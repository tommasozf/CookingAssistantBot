"""
grid_search.py

Hyperparameter grid search for the BERT-based NLU model.
Systematically tests combinations of hyperparameters and logs results.

Usage:
    python grid_search.py --output_dir ./grid_search_results
    python grid_search.py --quick  # For a quick test with fewer combinations
"""

import torch
import numpy as np
import random
import json
import csv
import os
import time
import argparse
from datetime import datetime
from itertools import product
from torch.utils.data import DataLoader
import torch.nn as nn
from sklearn.metrics import accuracy_score, classification_report, f1_score

from sic_framework.services.nlu.utils.dataset import (
    load_ontology, load_data, preprocess_data, NLURecipeDataset,
    fit_encoders, intent_label_encoder, slot_label_encoder
)
from sic_framework.services.nlu.utils.model import BERTNLUModel


# ============== HYPERPARAMETER SEARCH SPACE ==============
FULL_SEARCH_SPACE = {
    'num_epochs': [5, 7, 10, 15],
    'batch_size': [8, 16, 32, 64],
    'learning_rate': [1e-5, 2e-5, 3e-5, 5e-5],
    'max_length': [32, 48],
}

QUICK_SEARCH_SPACE = {
    'num_epochs': [5, 10],
    'batch_size': [16, 32],
    'learning_rate': [2e-5, 5e-5],
    'max_length': [32],
}


def set_seed(seed):
    """Set random seed for reproducibility."""
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)


def merge_slot_types(labels, label_encoder):
    """Merges BIO tags into unified slot types."""
    merged_labels = []
    for label in labels:
        tag = label_encoder.inverse_transform([label])[0]
        if tag == "O":
            merged_labels.append("O")
        else:
            merged_labels.append(tag.split("-")[-1])
    return merged_labels


def train_and_evaluate(model, train_dataset, test_dataset, num_epochs, batch_size, 
                       learning_rate, device, slot_label_encoder, intent_classes, 
                       slot_classes, early_stopping_patience=3):
    """
    Train the model and evaluate on test set.
    
    Returns:
        dict: Dictionary containing all evaluation metrics.
    """
    model.to(device)
    
    # Loss functions and optimizer
    intent_loss_fn = nn.CrossEntropyLoss()
    slot_loss_fn = nn.CrossEntropyLoss()
    optimizer = torch.optim.AdamW(model.parameters(), lr=learning_rate)
    
    # DataLoader
    dataloader = DataLoader(train_dataset, batch_size=batch_size, shuffle=True)
    
    # Training tracking
    best_loss = float('inf')
    patience_counter = 0
    training_losses = []
    
    # Training loop
    for epoch in range(num_epochs):
        model.train()
        epoch_loss = 0.0
        num_batches = 0
        
        for batch in dataloader:
            optimizer.zero_grad()
            
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            intent_labels = batch['intent_label'].to(device).long()
            slot_labels = batch['slot_labels'].to(device).long()
            
            intent_logits, slot_logits = model(input_ids, attention_mask)
            
            intent_loss = intent_loss_fn(intent_logits, intent_labels)
            slot_loss = slot_loss_fn(slot_logits.view(-1, slot_logits.shape[-1]), slot_labels.view(-1))
            loss = intent_loss + slot_loss
            
            loss.backward()
            optimizer.step()
            
            epoch_loss += loss.item()
            num_batches += 1
        
        avg_epoch_loss = epoch_loss / num_batches
        training_losses.append(avg_epoch_loss)
        
        # Early stopping check
        if avg_epoch_loss < best_loss:
            best_loss = avg_epoch_loss
            patience_counter = 0
        else:
            patience_counter += 1
            if patience_counter >= early_stopping_patience:
                print(f"    Early stopping at epoch {epoch + 1}")
                break
    
    # Evaluation
    model.eval()
    all_intent_preds, all_intent_labels = [], []
    all_slot_preds, all_slot_labels = [], []
    
    for example in test_dataset:
        with torch.no_grad():
            input_ids = example['input_ids'].unsqueeze(0).to(device)
            attention_mask = example['attention_mask'].unsqueeze(0).to(device)
            
            intent_logits, slot_logits = model(input_ids, attention_mask)
            intent_pred = torch.argmax(intent_logits, dim=1).item()
            intent_label = example['intent_label'].item()
            all_intent_preds.append(intent_pred)
            all_intent_labels.append(intent_label)
            
            slot_preds = torch.argmax(slot_logits, dim=2).squeeze().tolist()
            slot_labels = example['slot_labels'].tolist()
            valid_slot_labels = slot_labels[:len(slot_preds)]
            all_slot_preds.append(slot_preds)
            all_slot_labels.append(valid_slot_labels)
    
    # Compute metrics
    intent_accuracy = accuracy_score(all_intent_labels, all_intent_preds)
    
    # Intent F1 scores
    intent_report = classification_report(all_intent_labels, all_intent_preds, 
                                          target_names=intent_classes, output_dict=True, zero_division=0)
    intent_macro_f1 = intent_report['macro avg']['f1-score']
    intent_weighted_f1 = intent_report['weighted avg']['f1-score']
    
    # BIO Slot metrics
    flat_slot_labels = [label for seq in all_slot_labels for label in seq]
    flat_slot_preds = [label for seq in all_slot_preds for label in seq]
    
    slot_accuracy = accuracy_score(flat_slot_labels, flat_slot_preds)
    slot_report = classification_report(flat_slot_labels, flat_slot_preds, 
                                        target_names=slot_classes, output_dict=True, zero_division=0)
    slot_weighted_f1 = slot_report['weighted avg']['f1-score']
    slot_macro_f1 = slot_report['macro avg']['f1-score']
    
    # Merged slot type metrics (excluding 'O')
    merged_true = merge_slot_types(flat_slot_labels, slot_label_encoder)
    merged_pred = merge_slot_types(flat_slot_preds, slot_label_encoder)
    
    unique_slot_types = sorted(set(merged_true + merged_pred) - {"O"})
    merged_report = classification_report(merged_true, merged_pred, labels=unique_slot_types, 
                                          output_dict=True, zero_division=0)
    merged_macro_f1 = merged_report['macro avg']['f1-score']
    merged_weighted_f1 = merged_report['weighted avg']['f1-score']
    
    # Per-slot-type F1 scores
    per_slot_f1 = {}
    for slot_type in unique_slot_types:
        if slot_type in merged_report:
            per_slot_f1[slot_type] = merged_report[slot_type]['f1-score']
    
    return {
        'intent_accuracy': intent_accuracy,
        'intent_macro_f1': intent_macro_f1,
        'intent_weighted_f1': intent_weighted_f1,
        'slot_accuracy': slot_accuracy,
        'slot_weighted_f1': slot_weighted_f1,
        'slot_macro_f1': slot_macro_f1,
        'merged_macro_f1': merged_macro_f1,
        'merged_weighted_f1': merged_weighted_f1,
        'per_slot_f1': per_slot_f1,
        'final_training_loss': training_losses[-1] if training_losses else None,
        'epochs_trained': len(training_losses),
    }


def run_grid_search(args):
    """Run the hyperparameter grid search."""
    
    # Set seed
    set_seed(args.seed)
    
    # Device
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    
    # Select search space
    search_space = QUICK_SEARCH_SPACE if args.quick else FULL_SEARCH_SPACE
    
    # Load ontology and fit encoders
    ontology = load_ontology(args.ontology_path)
    fit_encoders(args.ontology_path)
    
    intent_classes = intent_label_encoder.classes_
    slot_classes = slot_label_encoder.classes_
    num_intents = len(intent_classes)
    num_slots = len(slot_classes)
    
    # Load data
    print("Loading data...")
    train_data = load_data(args.train_data)
    test_data = load_data(args.test_data)
    
    # Generate all hyperparameter combinations
    param_names = list(search_space.keys())
    param_values = list(search_space.values())
    all_combinations = list(product(*param_values))
    total_combinations = len(all_combinations)
    
    print(f"\n{'='*60}")
    print(f"GRID SEARCH CONFIGURATION")
    print(f"{'='*60}")
    print(f"Search space: {'QUICK' if args.quick else 'FULL'}")
    print(f"Total combinations to test: {total_combinations}")
    print(f"Parameters being searched:")
    for name, values in search_space.items():
        print(f"  - {name}: {values}")
    print(f"{'='*60}\n")
    
    # Results storage
    all_results = []
    best_result = None
    best_score = 0.0  # We'll optimize for merged_macro_f1
    
    # CSV file for incremental saving
    csv_path = os.path.join(args.output_dir, f"grid_search_results_{timestamp}.csv")
    
    # Run grid search
    for idx, combination in enumerate(all_combinations):
        params = dict(zip(param_names, combination))
        
        print(f"\n[{idx + 1}/{total_combinations}] Testing: {params}")
        start_time = time.time()
        
        try:
            # Preprocess data with current max_length
            processed_train = preprocess_data(train_data, max_length=params['max_length'])
            processed_test = preprocess_data(test_data, max_length=params['max_length'])
            
            train_dataset = NLURecipeDataset(processed_train, ontology, max_length=params['max_length'])
            test_dataset = NLURecipeDataset(processed_test, ontology, max_length=params['max_length'])
            
            # Create model
            model = BERTNLUModel(num_intents=num_intents, num_slots=num_slots)
            
            # Train and evaluate
            metrics = train_and_evaluate(
                model=model,
                train_dataset=train_dataset,
                test_dataset=test_dataset,
                num_epochs=params['num_epochs'],
                batch_size=params['batch_size'],
                learning_rate=params['learning_rate'],
                device=device,
                slot_label_encoder=slot_label_encoder,
                intent_classes=intent_classes,
                slot_classes=slot_classes,
                early_stopping_patience=args.early_stopping_patience
            )
            
            elapsed_time = time.time() - start_time
            
            # Combine params and metrics
            result = {
                **params,
                **{k: v for k, v in metrics.items() if k != 'per_slot_f1'},
                'training_time_seconds': elapsed_time,
            }
            
            # Add per-slot F1 scores as separate columns
            for slot_type, f1 in metrics.get('per_slot_f1', {}).items():
                result[f'f1_{slot_type}'] = f1
            
            all_results.append(result)
            
            # Check if this is the best result
            current_score = metrics['merged_macro_f1']
            if current_score > best_score:
                best_score = current_score
                best_result = result.copy()
                best_result['per_slot_f1'] = metrics['per_slot_f1']
            
            # Print summary
            print(f"    Intent Acc: {metrics['intent_accuracy']:.4f} | "
                  f"Slot F1: {metrics['slot_weighted_f1']:.4f} | "
                  f"Merged Macro F1: {metrics['merged_macro_f1']:.4f} | "
                  f"Time: {elapsed_time:.1f}s")
            
            # Save incrementally to CSV
            save_results_to_csv(all_results, csv_path)
            
        except Exception as e:
            print(f"    ERROR: {str(e)}")
            result = {**params, 'error': str(e)}
            all_results.append(result)
    
    # Save final results
    json_path = os.path.join(args.output_dir, f"grid_search_results_{timestamp}.json")
    with open(json_path, 'w') as f:
        json.dump({
            'search_space': search_space,
            'all_results': all_results,
            'best_result': best_result,
        }, f, indent=2)
    
    # Print summary
    print(f"\n{'='*60}")
    print("GRID SEARCH COMPLETE")
    print(f"{'='*60}")
    print(f"Results saved to:")
    print(f"  - CSV: {csv_path}")
    print(f"  - JSON: {json_path}")
    
    if best_result:
        print(f"\nBest Configuration (by merged_macro_f1):")
        print(f"  - num_epochs: {best_result['num_epochs']}")
        print(f"  - batch_size: {best_result['batch_size']}")
        print(f"  - learning_rate: {best_result['learning_rate']}")
        print(f"  - max_length: {best_result['max_length']}")
        print(f"\nBest Metrics:")
        print(f"  - Intent Accuracy: {best_result['intent_accuracy']:.4f}")
        print(f"  - Intent Macro F1: {best_result['intent_macro_f1']:.4f}")
        print(f"  - Slot Weighted F1: {best_result['slot_weighted_f1']:.4f}")
        print(f"  - Merged Macro F1: {best_result['merged_macro_f1']:.4f}")
        print(f"  - Merged Weighted F1: {best_result['merged_weighted_f1']:.4f}")
        
        if 'per_slot_f1' in best_result:
            print(f"\nPer-Slot F1 Scores:")
            for slot_type, f1 in sorted(best_result['per_slot_f1'].items()):
                print(f"  - {slot_type}: {f1:.4f}")
    
    return all_results, best_result


def save_results_to_csv(results, filepath):
    """Save results to CSV file."""
    if not results:
        return
    
    # Get all keys from all results
    all_keys = set()
    for r in results:
        all_keys.update(r.keys())
    
    # Remove 'per_slot_f1' dict if present (we flatten it)
    all_keys.discard('per_slot_f1')
    
    # Sort keys for consistent column order
    fieldnames = sorted(all_keys)
    
    with open(filepath, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(results)


def parse_arguments():
    """Parse command-line arguments for grid search."""
    parser = argparse.ArgumentParser(description="Hyperparameter Grid Search for NLU Model")
    
    # Data paths
    parser.add_argument("--ontology_path", type=str, default="./data/ontology.json",
                        help="Path to the ontology JSON file")
    parser.add_argument("--train_data", type=str, default="./data/train.json",
                        help="Path to training data")
    parser.add_argument("--test_data", type=str, default="./data/test.json",
                        help="Path to test data")
    
    # Grid search settings
    parser.add_argument("--output_dir", type=str, default="./grid_search_results",
                        help="Directory to save grid search results")
    parser.add_argument("--quick", action="store_true", default=False,
                        help="Use quick search space with fewer combinations")
    parser.add_argument("--early_stopping_patience", type=int, default=3,
                        help="Patience for early stopping")
    parser.add_argument("--seed", type=int, default=42,
                        help="Random seed for reproducibility")
    
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_arguments()
    run_grid_search(args)
