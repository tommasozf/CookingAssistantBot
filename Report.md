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
- **Intent classification:** <What it decides, why it’s needed.>
- **Slot filling:** <What it extracts (cuisine, dietary restrictions, mealType, time, etc.).>

### 4.2 Data & Labeling (If Applicable)
- Dataset source: <…>
- Label schema: intents list + slot types
- Train/val/test split: <…>
- Any augmentation: <…>

### 4.3 Evaluation Metrics
Include results for your best model, and optionally earlier iterations.

**Intent metrics**
| Model / Iteration | Accuracy | Precision | Recall | F1 |
|---|---:|---:|---:|---:|
| Baseline | <…> | <…> | <…> | <…> |
| Improved v1 | <…> | <…> | <…> | <…> |
| Final | <…> | <…> | <…> | <…> |

**Slot metrics**
| Model / Iteration | Precision | Recall | F1 |
|---|---:|---:|---:|
| Baseline | <…> | <…> | <…> |
| Improved v1 | <…> | <…> | <…> |
| Final | <…> | <…> | <…> |

**Confusion matrix (Intent)**
<Insert table or a small matrix-style list. Keep it readable.>

### 4.4 Threshold Compliance
Explain how your classifier compares to the **Intent and Slot Classifier Evaluation Thresholds**.
- Thresholds: <state required threshold(s)>
- Your results: <state your numbers>
- Pass/fail + interpretation: <be direct>

### 4.5 Challenges
- Ambiguous intents: <examples>
- Overlapping slots: <examples>
- Data sparsity: <…>
- Error analysis: <top 3 frequent errors + why>

### 4.6 Improvements Made
- Pre-trained models (e.g., BERT / embeddings): <what you used>
- Hyperparameter tuning: <what changed + why>
- Training methodology: <augmentation, balancing, prompts, etc.>
- Architecture modifications: <…>
- Impact: <what improved and by how much>

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

## 8. Conclusion (≈1 page)

### 8.1 Project Outcomes
Summarize what you built + what it achieves.
- Outcome 1: <…>
- Outcome 2: <…>
- Outcome 3: <…>

### 8.2 Reflection
- What went well: <teamwork, design decisions, etc.>
- What could be improved: <time management, data quality, evaluation, etc.>

### 8.3 Future Work
List 3–6 concrete improvements/extensions.
- <…>
- <…>
- <…>

---

## (Optional) References
- <Citation / link>
- <Citation / link>

## (Optional) Appendices
> Remember: main report must be self-contained.
- Appendix A: <extra tables>
- Appendix B: <full confusion matrices>
- Appendix C: <additional dialogue logs>

