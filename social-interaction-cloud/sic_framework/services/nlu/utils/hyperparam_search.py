"""
Hyperparameter search for NLU model training.
Tests different combinations and reports best configuration.
"""

import torch
import numpy as np
import random
import time
import itertools
from tabulate import tabulate

from sic_framework.services.nlu.utils.dataset import (
    load_ontology, load_data, preprocess_data, NLURecipeDataset,
    fit_encoders, intent_label_encoder, slot_label_encoder
)
from sic_framework.services.nlu.utils.train import train_model
from sic_framework.services.nlu.utils.evaluation import evaluate
from sic_framework.services.nlu.utils.model import BERTNLUModel


def run_hyperparameter_search():
    # Set seed for reproducibility
    SEED = 42
    random.seed(SEED)
    np.random.seed(SEED)
    torch.manual_seed(SEED)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}")

    # Load data
    print("Loading data...")
    fit_encoders("./data/ontology.json")
    ontology = load_ontology("./data/ontology.json")

    intent_classes = intent_label_encoder.classes_
    slot_classes = slot_label_encoder.classes_
    num_intents = len(intent_classes)
    num_slots = len(slot_classes)

    print(f"Number of intents: {num_intents}")
    print(f"Number of slot types: {num_slots}")

    train_data = load_data("./data/train.json")
    test_data = load_data("./data/test.json")

    print(f"Training examples: {len(train_data)}")
    print(f"Test examples: {len(test_data)}")

    # Hyperparameter grid
    param_grid = {
        'num_epochs': [3, 5, 7],
        'batch_size': [16, 32],
        'learning_rate': [2e-5, 5e-5],
        'max_length': [32, 64]
    }

    # Generate all combinations
    keys = param_grid.keys()
    combinations = list(itertools.product(*param_grid.values()))

    print(f"\nTesting {len(combinations)} hyperparameter combinations...\n")

    results = []
    best_score = 0
    best_params = None

    for i, combo in enumerate(combinations):
        params = dict(zip(keys, combo))
        print(f"[{i+1}/{len(combinations)}] Testing: {params}")

        try:
            # Preprocess with current max_length
            processed_train = preprocess_data(train_data, max_length=params['max_length'])
            processed_test = preprocess_data(test_data, max_length=params['max_length'])

            train_dataset = NLURecipeDataset(processed_train, ontology, max_length=params['max_length'])
            test_dataset = NLURecipeDataset(processed_test, ontology, max_length=params['max_length'])

            # Create and train model
            model = BERTNLUModel(num_intents=num_intents, num_slots=num_slots).to(device)

            start_time = time.time()
            model = train_model(
                model=model,
                dataset=train_dataset,
                num_epochs=params['num_epochs'],
                batch_size=params['batch_size'],
                learning_rate=params['learning_rate'],
                device=device
            )
            train_time = time.time() - start_time

            # Evaluate
            metrics = evaluate(
                model, test_dataset,
                intent_classes, slot_classes, slot_label_encoder,
                device=device
            )

            # Calculate combined score (weighted average of intent and slot F1)
            intent_f1 = metrics.get('intent_f1', 0)
            slot_f1 = metrics.get('slot_f1', 0)
            combined_score = 0.5 * intent_f1 + 0.5 * slot_f1

            result = {
                **params,
                'intent_acc': round(metrics.get('intent_accuracy', 0), 4),
                'intent_f1': round(intent_f1, 4),
                'slot_f1': round(slot_f1, 4),
                'combined': round(combined_score, 4),
                'time_s': round(train_time, 1)
            }
            results.append(result)

            print(f"   -> Intent F1: {intent_f1:.4f}, Slot F1: {slot_f1:.4f}, Combined: {combined_score:.4f}")

            if combined_score > best_score:
                best_score = combined_score
                best_params = params.copy()
                # Save best model
                torch.save(model.state_dict(), "./checkpoints/model_checkpoint_best.pt")
                print(f"   -> New best! Saved model.")

        except Exception as e:
            print(f"   -> Error: {e}")
            results.append({**params, 'intent_acc': 0, 'intent_f1': 0, 'slot_f1': 0, 'combined': 0, 'time_s': 0, 'error': str(e)})

    # Sort results by combined score
    results_sorted = sorted(results, key=lambda x: x.get('combined', 0), reverse=True)

    # Print results table
    print("\n" + "="*80)
    print("HYPERPARAMETER SEARCH RESULTS (sorted by combined score)")
    print("="*80)

    headers = ['epochs', 'batch', 'lr', 'max_len', 'intent_acc', 'intent_f1', 'slot_f1', 'combined', 'time_s']
    table_data = []
    for r in results_sorted:
        table_data.append([
            r['num_epochs'], r['batch_size'], r['learning_rate'], r['max_length'],
            r.get('intent_acc', 'ERR'), r.get('intent_f1', 'ERR'),
            r.get('slot_f1', 'ERR'), r.get('combined', 'ERR'), r.get('time_s', 'ERR')
        ])

    print(tabulate(table_data, headers=headers, tablefmt='grid'))

    print(f"\nBest hyperparameters: {best_params}")
    print(f"Best combined score: {best_score:.4f}")
    print(f"\nBest model saved to: ./checkpoints/model_checkpoint_best.pt")

    return best_params, results_sorted


if __name__ == "__main__":
    run_hyperparameter_search()
