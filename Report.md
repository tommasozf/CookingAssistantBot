<!--
Report.md — Conversational Recipe Recommendation Agent
Rule of thumb: 1 page ≈ 500 words. Total main text ≤ 10 pages (≈ 5000 words).
Keep the main report self-contained; appendices are optional extras.
-->

# <Project Title>  
**Group <##>**  
**Students:** <Name Surname> (<student email>) — <student number>  
<Add more lines as needed>

---

## 1. Title (≈0.25 page)
> **Goal:** Eye-catching, informative title + required group/student info above.

---

## 2. Introduction (≈0.75 page)

### 2.1 Project Overview
- **What is a conversational recipe recommendation agent?**  
  <Define clearly, 2–4 sentences.>
- **Purpose / value:**  
  <Why it exists, what problem it solves.>

### 2.2 Task-Oriented Spoken Dialogue Systems (TOSDS)
- **Definition:** <1–3 sentences.>
- **Why TOSDS fits recipe recommendation:**  
  <Structured task, constraints, user goals, etc.>

### 2.3 Goals (Concrete + Specific)
List 3–6 goals that match *your* implementation.
- G1: <e.g., Recommend recipes personalized to cuisine + diet constraints>
- G2: <e.g., Support exclusions (ingredients/cuisines/meal types)>
- G3: <e.g., Robust clarification when information is missing>
- G4: <…>

---

## 3. How Does Your Conversational Agent Work? (≈2 pages)

### 3.1 Primary Use Cases
Describe what users can do.
- Use case A: <e.g., “Recommend me a spicy Korean chicken recipe”>
- Use case B: <e.g., “Show me vegetarian dinners under 30 minutes”>
- Use case C: <e.g., “Exclude peanuts and dairy”>
- Use case D: <…>

### 3.2 Pipeline / System Architecture
Explain components and how they connect.
- **Input:** <text/speech → text>
- **NLU:** intent recognition + slot filling
- **Dialogue management:** state tracking, prompts, confirmations
- **Database/KB access:** querying recipes/ontology/Prolog facts
- **NLG / Response generation:** template-based or model-based

> Optional: add a simple diagram in Markdown (ASCII) or link to an image stored in repo.

### 3.3 Conversational Flow (Typical Interaction Walkthrough)
Walk through one full example end-to-end.
1. User: "<example utterance>"
2. Agent: "<response>"
3. NLU output (intent + slots):  
   - Intent: `<…>`  
   - Slots: `<slot>=<value>, ...`
4. Backend query: <what is queried and how>
5. Result handling: <ranking, filtering, fallbacks>
6. Final response to user: "<…>"

### 3.4 Testable Example Dialogues (We can try these)
Provide 5–10 examples that reliably work in your system.

**Example 1 — Basic recommendation**
- User: "<…>"
- Expected behavior: <…>

**Example 2 — Missing slot → clarification**
- User: "<…>"
- Agent should ask: "<…>"
- Then user: "<…>"
- Agent returns: "<…>"

**Example 3 — Exclusion**
- User: "<…>"
- Expected behavior: <…>

**Example 4 — Multi-constraint**
- User: "<…>"
- Expected behavior: <…>

**Example 5 — Failure mode**
- User: "<…>"
- Expected fallback: <…>

---

## 4. Intent and Slot Classifier (≈1–2 pages)

### 4.1 Why Intent + Slots Matter
Our pipeline workflow ensures that when a user provides spoken input, it is converted into text and then analyzed to understand its semantic meaning. These inputs vary in form, ranging from questions and requests to direct orders, and our model is designed to recognize two main components: the user's primary goal, known as intent, and the specific details provided, known as slots. This recognised slots and intents are needed, since pipeline's next components are designed to perform their search based on the extracted and defined intents or slots. 

### 4.2 Data & Labeling (If Applicable)
Data used for the training part is first given as a piece of the raw data in a JSON format , with a unique ID, the text of the user’s input, intent of the input and a dictionary with slots where each slot type is mapped to their values.


Label schema: 

The pipeline uses a multi-layered labeling schema to enable joint intent classification and entity extraction. The intent list consists of 14 distinct categories, ranging from task-oriented commands like addFilter and recipeRequest to conversational signals such as greeting and appreciation. 
For the slot-filling task, the schema defines 11 high-level slot types including cuisine, ingredient, dietaryRestriction, and duration, which allow the model to capture various details of a user’s request.
To handle these entities at the token level, we use the BIO format, which marks the start of a value with a B- prefix and any continuing tokens with an I- prefix. 
By combining these global intent labels with token-level BIO tags, the model can understand what the user wants to do and which specific parameters need to be extracted to capture the request.

Train/val/test split: 
A fixed training ratio of 0.8 is used, resulting in eighty percent of the data being allocated to the training set and twenty percent to the test set. Because no validation path exists, the model uses training loss for performance monitoring and early stopping criteria during the optimization process.


Any augmentation:
We used synonym replacement to help the model focus on semantic meaning rather than specific word choices. 
Slot value swapping was also applied, allowing us to rotate different ingredients or cuisines within the same sentence structure to improve entity recognition. 
Back-translation was used to introduce syntactic variety by translating utterances into a pivot language and back to English. 


### 4.3 Evaluation Metrics
Include results for your best model, and optionally earlier iterations.

**Intent metrics**
| Model / Iteration | Accuracy | Precision | Recall | F1 |
|---|---:|---:|---:|---:|
| Baseline | 0.89 | 0.90 | 0.89 | 0.89 |
| Improved v1 | <…> | <…> | <…> | <…> |
| Final | 0.93 | 0.93 | 0.93 | 0.93 |

**Slot metrics**
| Model / Iteration | Precision | Recall | F1 |
|---|---:|---:|---:|
| Baseline | 0.98 | 0.98 | 0.98 | 0.98 |
| Improved v1 | <…> | <…> | <…> | 
| Final | 0.995 | 1.00 | 1.00 | 0.995  |

**Confusion matrix (Intent)**
|Intent|	Model|	Precision	|Recall	|F1-Score	| Support
|---|---:|---:|---:|---:| ---:|
|noMoreFilters | Baseline |	0.90 |	0.36 |	0.51 |	100
|               |Improved |	0.90 |	0.72 |	0.80 |	100
|addFilter  |	Baseline | 	0.95 |	0.97 |	0.96 |	917
|           | Improved |	0.97	 | 0.99  |	0.98 |	917
|Weighted Avg |	Baseline |	0.90 |	0.89 |	0.89 |	2331
|             |  Improved |	0.93 |	0.93 |	0.93 |	2331

### 4.4 Threshold Compliance
The project established success thresholds based on the initial baseline metrics.
The required Intent Classification Accuracy was set at 0.89. 
For the slot filling task, the required benchmark was a weighted average F1-score of 0.86,

The evaluation of the improved model shows an increase across all core metrics:
Intent Classification Accuracy: 0.93
Merged Slot Weighted F1-score: 0.995
Token-level Slot Accuracy: 0.995

The improved classifier passed all evaluation criteria, exceeding the required intent accuracy by 4% and the slot F1-score by about 13.
Furthermore the intent accuracy of 93% confirms that the system can correctly categorize user goals with minimal error.


### 4.5 Challenges
Ambiguous intents: Semantic overlap between classes created significant confusion in the initial stages of the project. Specifically, the baseline model struggled to distinguish between disconfirmation and fallback, which resulted in low F1-scores of 0.73 and 0.71, respectively. 
The noMoreFilters intent proved to be the most difficult for the baseline to isolate, yielding a recall of only 0.36. 

Overlapping slots: Distinguishing between filterType, cuisine, and ingredient was difficult because these slots often share similar vocabulary. In the baseline version, this led to a low recall of 0.59 for the filterType category.

Data sparsity: Extreme class imbalance was a major hurdle for the baseline, where high-support intents like addFilter (917 samples) dwarfed minority labels such as deleteParameter (104 samples).

Error analysis: The baseline evaluation revealed three top errors: 
1) low recall for noMoreFilters
2) confusion between filter categories and values
3) hyperparameter sensitivity
   
Assigning the correct training settings, such as number of epochs, learning rate, and batch size, was a persistent challenge that led to instability in early tests. 


### 4.6 Improvements Made
Pre-trained models (e.g., BERT / embeddings): The model utilizes a pre-trained BERT backbone to generate contextualized embeddings

Hyperparameter tuning: We transitioned from the baseline defaults of 3 epochs and a batch size of 2 to a more robust configuration of 7 epochs and a batch size of 32. This change was critical for stabilizing gradient updates and allowing the model sufficient time to converge on a joint loss for both intent and slot tasks.

Training methodology: We implemented the AdamW optimizer to prevent overfitting and utilized a multi-task learning approach that sums CrossEntropyLoss for both objectives during the forward pass. Data was shuffled and split with a 0.8 training ratio to ensure diverse exposure within each batch.

Architecture modifications: The system features dual linear heads branching from the BERT encoder, allowing for simultaneous global intent classification and token-level BIO slot tagging. The slot-filling head uses sequence reshaping to compute loss across all tokens, ensuring precise alignment between the text and extracted entities.

Impact: These refinements boosted intent accuracy from 89% to 93% and nearly doubled the recall for difficult classes like noMoreFilters. Slot filling performance saw the most significant gain, reaching a 99.5% F1-score compared to the baseline's 86%.


---

## 5. Exclusion (≈2 pages)

### 5.1 What “Exclusion” Means in Your System
Define scope explicitly:
- Excluding **ingredients**: <…>
- Excluding **cuisines**: <…>
- Excluding **mealTypes**: <…>

### 5.2 Implementation Approach
Explain exactly how it works in your pipeline.
- Where exclusion is applied: (NLU → dialogue state → query → ranking → response)
- Representation of exclusions: <lists, ontology classes, Prolog predicates, etc.>
- Rule logic: <how conflicts are resolved, precedence rules>

### 5.3 Tools / Technologies
Describe integrations:
- MARBEL: <role in pipeline>
- Prolog: <facts/rules/queries used>
- Python: <glue logic / filtering / orchestration>
- Ontology updates: <what was added or changed>

### 5.4 Pros and Cons (Be Critical)
**Strengths**
- <what it does well, with examples>

**Limitations**
- <what it cannot do, edge cases, failure modes>

### 5.5 Performance & Trade-offs
Compare exclusion vs inclusion-only.
- Accuracy / success rate: with vs without exclusion
- Impact on user satisfaction: <summary of evidence>
- Latency or complexity trade-offs: <if any>

**Comparison table**
| Setting | Task success rate | Avg. turns to success | Common failures |
|---|---:|---:|---|
| Inclusion-only | <…> | <…> | <…> |
| With exclusion | <…> | <…> | <…> |

### 5.6 Testable Exclusion Examples
Provide 3–6 interactions.
- User: "<Exclude X and recommend Y>"
- Expected: <…>

---

## 6. Extensions to the Pipeline (≈1 page)

### 6.1 Summary of Extensions
List what you added beyond baseline requirements.
- Extension A: <…>
- Extension B: <…>
- Extension C: <…>

### 6.2 Motivation & Impact
For each extension:
- Why you added it
- What problem it solves
- How it improves experience or capabilities

### 6.3 Pipeline Integration Choice
- Connected to custom NLU: **Yes/No**
- Continued using Dialogflow: **Yes/No**
- Rationale + implications: <brief>

---

## 7. Pilot User Study (≈1 page)

### 7.1 Study Setup
- Participants: <who, how many, background>
- Tasks: <what they were asked to do>
- Data collection: <survey, observation, logs, etc.>
- Procedure: <short step-by-step>

### 7.2 Results (Descriptive Statistics)
No need for charts—tables are enough.

**Quantitative**
| Metric | Value |
|---|---:|
| Task success rate | <…> |
| Error rate | <…> |
| Avg. response time / turns | <…> |
| Other | <…> |

**Qualitative**
- Key feedback themes:
  - <theme 1> — “<short quote>”
  - <theme 2> — “<short quote>”
  - <theme 3> — “<short quote>”

### 7.3 Analysis
- What worked well: <…>
- What needs improvement: <…>
- Lessons learned + future implications: <…>

---

## 8. Conclusion 

### 8.1 Project Outcomes
We developed GLaDOS, a conversational agent designed to assist with discovering, personalising, and managing recipe searches through dialogue. The implemented pipeline successfully accomplishes language understanding, contextual dialogue management, and recipe retrieval and display.
- Outcome 1: High Accuracy NLU system
- Outcome 2: Implementation of dialog manager logic
- Outcome 3: Strategic architecture of the whole pipeline (BERT, Google STT, updated visuals)

### 8.2 Reflection
During development, we trained an intent and slot classifier that achieved an intent accuracy of 93.9%, a slot F1 score of 99.5%, and a slot accuracy of 99.5%, exceeding the specified project thresholds. 
The model was built on a BERT-based architecture as the underlying pre-trained model, which provided a strong foundation for robust language understanding. We chose this custom approach over using a platform like Dialogflow to maintain greater control and specificity. For speech recognition, we used Google STT after determining it was more reliable and faster than Whisper, which proved too slow and inaccurate for our use case. These design decisions resulted in a more reliable and controllable pipeline.
The full pipeline enabled a complete user journey. From an initial greeting, through recipe recommendations based on user-provided filters, to the display of a chosen recipe and the conclusion of the session.

However, the model exhibited systematic errors. For example, it correctly identified the mealType slot (e.g., breakfast, lunch, dinner) only in short, direct prompts, and often failed when the target phrase appeared within longer or more natural sentences. It also occasionally misclassified numerical values, such as ingredient counts as the duration slot.
Following the pilot study, we recognised several integration pitfalls. The pipeline could have been made more robust, and a dedicated validation set would have helped verify that the model was not overfitting. A key lesson is that a larger, more varied training dataset would reduce overfitting and improve the agent’s ability to process longer, more natural sentences.
Moreover, the dialogue manager followed a strict, linear script. It expected users to provide filters in a predictable sequence. If a user didn’t follow that, for example, by asking a clarifying question or by providing filters in an unexpected order, the system lacks the flexibility to handle the interruption and gracefully guide the conversation back on track and agent has to be restarted. 


### 8.3 Future Work
- adding a validation set with also more challenging natural language examples to evaluate model better and monitor overfitting
- adding more extensions to enhance flexibility, for example, adding an undo button to handle interruptions and preventing the conversation flow from getting stuck
- creating additional training examples for the slots, like mealType, in which model performed poorly in order to teach better patterns and improve model performance on edge cases

---

## (Optional) References
- <Citation / link>
- <Citation / link>

## (Optional) Appendices
> Remember: main report must be self-contained.
- Appendix A: <extra tables>
- Appendix B: <full confusion matrices>
- Appendix C: <additional dialogue logs>

