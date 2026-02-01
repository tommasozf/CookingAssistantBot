
**Group R3**  
**Students:** 
-  Krista K. Dērica- 2857960 - k.k.derica@student.vu.nl,
-  Louis G.P. Battle - 2845431 - l.g.p.battle@student.vu.nl,
-  Nicolau R. Vilaclara Enomoto - 2860722 - n.r.vilaclaraenomoto@student.vu.nl,
-  Bartosz J. Szajda- 2763456 - b.j.szajda@student.vu.nl,
-  Tommaso Zambelli Franz - 2825713 - t.zambellifranz@student.vu.nl ,
-  Youssef El Haddouchi - 2811420 - y.el.haddouchi@student.vu.nl

---

## 1. Glados: Finding Recipes Through Conversation 
Design and Implementation of a Task-Oriented Spoken Dialogue System


## 2. Introduction 

### 2.1 Project Overview
- Our conversational recipe recommendation agent is a system that supports users in finding recipes through natural language interaction. Instead of relying on traditional search interfaces with multiple filters, an agent like this allows users to express preferences conversationally, like specifying a certain cuisine or ingredients. The system interprets these preferences and narrows down the available options step by step with the intention to find a suitable recipe.
  
- Glados is a task-oriented spoken dialogue system developed for this purpose. Task-oriented dialogue systems are designed to help users complete well-defined tasks through structured interaction instead of engaging in open-ended conversation. In Glados the task consists of guiding the user toward a single recipe that matches their constraints. The recipe recommendation domain is suited to a task-oriented conversational approach. Recipes can be described using a finite set of attributes that align naturally with slot-filling dialogue strategies. Users often begin a recipe search without a fully specified goal and a conversational interface supports this exploratory behavior allowing preferences to be added, modified, or corrected during the interaction. 

### 2.2 Goals 
- The main goal with our project is to design and implement a task-oriented spoken dialogue system which supports personalized recipe recommendation through conversational interactions, to enable users to express constraints related to cuisine, dietary requirements, ingredients, etc..
- All of this to support correction and refinement of preferences during the interaction and to integrate voice-based interaction with visual recipe overviews and presentations.
- The project demonstrates how a task-oriented spoken dialogue system can be applied effectively to a practical recommendation task in a structured and well-defined domain.

---

## 3. How Does Your Conversational Agent Work? 

### 3.1 Primary Use Cases
Our Glados is designed to support conversational recipe recommendation through a limited set of pre-defined use cases. All interactions are centered around helping the user identify and confirm a suitable recipe based on spoken preferences. 

- (A) A primary use case is requesting a recipe recommendation using one or more constraints, for example one might specify preferences related to                     cuisine type, preparation time, or dietary requirements such as “Recommend me an Albanian recipe with olive oil” or “Show me vegetarian dinners”.
- (B) Users can incrementally add constraints or exclusions at any point during the interaction, for example by saying ‘No olive oil’ or ‘With garlic’.               These refinements are combined with existing preferences and applied through exclusion-based filtering, allowing users to narrow down results                   without restating every constraint.
- (C) the agent supports confirmation and rejection of individual recipes. After a recipe is presented in detail, users can confirm their choice or                   reject it and request an alternative. This allows users to remain in control of the final selection while the system manages the dialogue flow.



### 3.2 Pipeline / System Architecture
- Our Glados follows a pipeline typical of task-oriented spoken dialogue systems. The input is provided through the user's speech and converted to text     using speech recognition. The transcribed input is passed to the natural language understanding (NLU) component, where intent recognition and slot filling are performed. Intents represent the user’s communicative goal, such as specifying preferences, refining constraints, confirming a recipe, or rejecting a proposal. Slots capture relevant information like cuisine type, dietary restrictions, ingredients, or preparation time.

- Dialogue management is implemented in MARBEL, a Prolog-based framework for conversational agents. The dialogue manager maintains the current dialogue state and includes active filters and the current interaction phase. Based on this state, it determines the appropriate next action, think of things like presenting recipe options or moving to clarification.

- The dialogue manager queries a structured recipe database represented as Prolog facts. These queries apply the active constraints to filter the available recipes. The number of matching results influences the system’s behavior, for example whether further refinement is required or whether a visual recipe overview can be shown.

- System responses are generated using template-based natural language generation and communicated to the web frontend via the Social Interaction Cloud framework. The frontend updates the user interface to reflect the current dialogue state.

- The processing pipeline of Glados starts with spoken user input, which is converted into text through speech-to-text processing. After this the transcribed input is analyzed by the NLU component which performs intent recognition and slot filling. Based on this information the dialogue management component updates the dialogue state and applies the system’s decision logic. Afterwards the active preferences are used to query the recipe database. At last, the response is generated and presented to the user through both spoken output and visuals.

### 3.3 Conversational Flow 
User: “I want some Albanian food please.”

NLU output:
Intent:specify_preferences
Slots: cuisine = Albanian

Backend query: 
The dialogue manager stores the extracted slot and queries the recipe database for Albanian recipes.

Result handling: 
The result set contains multiple matching recipes, so the system requests further refinement.

Agent: “I found several Albanian recipes. Do you have any dietary restrictions or ingredient preferences?”

User: “I want it to be vegetarian.”

NLU output: 
Intent: refine_preferences 
Slots: diet = vegetarian

Backend query: The vegetarian constraint is added to the active filters, and the recipe database is queried again.

Result handling: The result set is reduced, still containing multiple options, allowing the system to proceed to a visual overview.

Agent: "Great." “I’m showing you some vegetarian Albanian recipes. Would you like to choose one?”

User: “With tomato sauce.”

NLU output: 
Intent: refine_preferences 
Slots: ingredient = tomato sauce

Backend query: The ingredient-based constraint is applied, further narrowing down the result set.

Final response to user: Our system presents a detailed view of a selected vegetarian Albanian recipe with tomato sauce and asks users to confirm or reject.

User: “Yes.”

NLU output: 
Intent: confirm_recipe

Interaction outcome: 
The recipe is confirmed, and the interaction concludes.

### 3.4 Testable Example Dialogues 


**Example 1 — Basic request:**
 Basic cuisine-based recommendation
 - User: “Albanian food.” 
 - Expected behavior: The system applies a cuisine filter and, if many recipes match, asks the user to further refine their preferences.

**Example 2 — Missing slot → clarification**
- User: "<…>"
- Agent should ask: "<…>"
- Then user: "<…>"
- Agent returns: "<…>"

**Example 3 — Exclusion**
- User:  “No meat.”
- Expected behavior: All recipes containing meat products are excluded from the result set.

**Example 4 — Multi-constraint**
- User: “Vegetarian Albanian food with feta cheese.” 
- Expected behavior: The system applies all constraints and presents a limited set of matching vegetarian Albanian recipes.

**Example 5 — Failure mode**
- User: “No, not that one.”
- Expected behavior: The system returns to the recipe overview and allows the user to select an alternative recipe that still satisfies the active constraints.

**Example 6 — Confirmation**
- User: “Yes.”
- Expected behavior: The system confirms the selected recipe and completes the interaction.

**Example 7 — Ingredient-based preference**
- User: “Albanian food with feta cheese.”
- Expected behavior: The system filters Albanian recipes and retains only those that include feta cheese

---
## 4. Intent and Slot Classifier 

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
| Final | 0.93 | 0.93 | 0.93 | 0.93 |

**Slot metrics**
| Model / Iteration | Precision | Recall | F1 |
|---|---:|---:|---:|
| Baseline | 0.98 | 0.98 | 0.98 | 0.98 |
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

## 5.1 Motivation and Design Rationale

Glados implements both inclusion and exclusion filtering to reflect natural user search patterns. While inclusion filters specify desired attributes (e.g., "Italian cuisine"), exclusion filters express constraints to avoid (e.g., "no dairy"). This dual approach is more efficient than inclusion-only filtering, particularly for dietary restrictions and allergies where users would otherwise need to enumerate all acceptable alternatives.

Exclusion filtering addresses common use cases including dietary restrictions (vegetarian, vegan), allergen avoidance (no nuts, no shellfish), and personal preferences (no cilantro). Supporting both strategies allows users to express preferences naturally without cognitive overhead.

## 5.2 Exclusion Mechanism

The exclusion mechanism is implemented in `recipe_selection.pl` using Prolog's negation-as-failure operator (`\+`):

```prolog
applyFilter('excludeingredient', Ingredient, RecipeIDsIn, RecipeIDsOut) :-
    findall(RecipeID,
        (member(RecipeID, RecipeIDsIn), \+ hasIngredient(RecipeID, Ingredient)),
        RecipeIDsOut).
```

**Ingredient-Level Exclusions** target specific ingredients by name. When a user says "no olive oil," the system filters recipes where `ingredient(RecipeID, 'olive oil')` fails, removing all recipes containing olive oil.

**Category-Level Exclusions** operate on ingredient types using a hierarchical classification system in `ingredient_hierarchies.pl`:

```prolog
typeIngredient('chicken thighs', 'meat').
typeIngredient('beef steak', 'meat').
typeIngredient('pork ribs', 'meat').
```

When a user excludes "meat," the system removes all recipes containing any ingredient classified as meat through the type-aware predicate:

```prolog
hasIngredient(RecipeID, IngredientType) :-
    ingredient(RecipeID, SpecificIngredient),
    typeIngredient(SpecificIngredient, IngredientType).
```

**Dietary Restrictions** are implemented as inclusion filters that implicitly exclude non-compliant ingredients. A "vegetarian" filter ensures all recipe ingredients satisfy `typeIngredient(Ingredient, 'vegetarian')`, effectively excluding meat, fish, and poultry.

**Conflict Resolution**: When inclusion and exclusion filters conflict (e.g., "include chicken" vs. "exclude meat"), the system implements an inclusion-overrides-exclusion strategy. Conflicts are detected via:

```prolog
conflict(ingredient = Value, excludeingredient = Value).
conflict(ingredienttype = Value, excludeingredienttype = Value).
```

The dialogue manager automatically removes conflicting filters from memory, prioritizing the user's most recent explicit request.

**Filter Application**: Filters are applied recursively in a cascade pattern:

```prolog
recipesFiltered(RecipeIDs, [], RecipeIDs).  % Base case

recipesFiltered(RecipeIDsIn, [ParamName = Value | Filters], RemainingRecipeIDs) :-
    applyFilter(ParamName, Value, RecipeIDsIn, RecipeIDsOut),
    recipesFiltered(RecipeIDsOut, Filters, RemainingRecipeIDs).
```

## 5.3 Examples of Exclusion Patterns

- **"No olive oil"**: Removes recipes where `ingredient(RecipeID, 'olive oil')` succeeds
- **"No meat"**: Removes all recipes containing ingredients with `typeIngredient(Ingredient, 'meat')`
- **"Vegetarian"**: Retains only recipes where all ingredients satisfy vegetarian constraint
- **"Albanian food with feta cheese but no meat"**: Applies cuisine filter, ingredient inclusion, then meat exclusion sequentially

## 5.4 Challenges and Solutions

**Incomplete Ingredient Data**: The system addresses this through comprehensive ingredient tagging and type-based inference. However, ingredients not recorded in the database cannot be excluded—an inherent limitation of closed-domain databases.

**Ambiguous Exclusions**: Hierarchical ingredient classification disambiguates broad categories through explicit type mappings. Terms like "seafood" map to all fish and shellfish via `typeIngredient/2` predicates. Ambiguities around ingredient properties (spicy, sweet) are not fully addressed.

**Empty Result Sets**: When filters eliminate all recipes, the system employs multiple recovery strategies:
1. Immediate feedback: "I could not find a recipe that matches all preferences. Please remove a filter."
2. Conflict detection prevents impossible combinations
3. Visual filter chips allow easy constraint removal
4. Dialogue patterns trigger recovery flows when `recipesFiltered([])` returns empty


**NLU Parsing Errors**: The intent classifier occasionally misinterprets mixed inclusion/exclusion utterances; for example, "Korean food with no cheese" may incorrectly generate two exclusion filters (exclude Korean, exclude cheese) rather than one inclusion and one exclusion, resulting in opposite behavior from user intent.

**Current Limitation**: The system cannot suggest which specific filter to remove. Users must manually identify overly restrictive constraints.
one 

---

# Section 6: Extensions to the Pipeline

## 6.1 Summary of Extensions

Glados implements multiple extensions beyond the baseline requirements, going from slot-filling to a more user-focused system. The extensions fall into 3 categories:

### Core Extensions Implemented:

**Extension A: Visual Interface Enhancements**
- Dual-view display modes (text-based and visual grid)
- Visual recipe cards with images (4-column responsive grid)
- Active filter display with colored chips
- Progress tracking and recipe counter visualization
- Detailed recipe presentation with metadata pills

**Extension C: GLaDOS Personality & Humor**
- 518 lines of scripted responses
- Sardonic, Portal-themed personality
- Context-aware acknowledgments
- Humorous error messages and feedback

**Extension D: Advanced Dialogue Strategies**
- Mixed-initiative interaction (user can add filters anytime)
- Multi-layered context retention system
- Multi-modal input (voice and click)
- Progressive refinement with ambiguity handling
---

### Extension A: Visual Interface Enhancements

**Motivation:**
Text-only recipe recommendations lack visual appeal and make it difficult for users to browse options. Visual presentation with images, structured layouts, and filter visualization significantly improves usability and engagement.

**Implementation:**

**1. Recipe Overview Display**
The system uses two adaptive display modes:
- **Text-based (recipe_overview.html)**: For large result sets (>15 recipes), prompts further refinement with active filter display
- **Visual grid (recipe_overview2.html)**: For <=15 recipes, shows 4-column responsive grid with recipe cards containing image, title, and select button

**2. Detailed Recipe Presentation (recipe_confirmation.html)**
- Recipe image
- Title with metadata pills (time, servings, cuisine)
- Ingredient list (unordered) with quantities
- Step-by-step instructions (ordered list)

**3. Active Filter Display**
Filters shown as colored chips with dynamic rendering:
- Inclusion filters: Warm colors (honey gold, orange)
- Exclusion filters: Red tones 
- Real-time updates via SocketIO `filters` event

**4. Interaction State Visualization**
- Recipe counter showing current matches
- Progress bar with filtering steps (800 → 150 → 45 → 12)
- Turn indicators (microphone enabled/disabled)
- Page transitions reflecting dialogue states

**Design System:**
The interface uses a glassy design with:
- Semi-transparent backgrounds
- Soft shadows and borders
- Rounded corners
- Smooth color transitions
- Responsive typography

**Impact:**
Visual enhancements significantly improve user experience:
- **Browsing efficiency**: Grid layout allows quick visual comparison of 15 recipes simultaneously
- **Filter awareness**: Color-coded chips make active constraints immediately visible
- **Progress feedback**: Counter and progress bar help users understand filtering impact
- **Aesthetic appeal**: Modern, polished interface increases engagement
- **Accessibility**: Dual-view approach supports both refinement and browsing workflows

---

### Extension B: Glados Personality & Humor

**Motivation:**
The basic conversational nature of the pipeline is generic and fails to improve user experience. A distinctive personality enhances engagement, memorability, and user enjoyment. The Glados character (from Portal series) provides a recognizable, humorous persona that transforms recipe recommendation into an entertaining experience.

**Implementation:**
The responses.pl file contains 518 lines of scripted responses organized by intent and context. Examples include:

**Greetings:**
- "Welcome. I am here to help you select a recipe. This should be simple, even for a human."
- "Hello there. I am your personal recipe assistant. Together, we will find something for you to cook. How exciting."

**Errors:**
- "I have access to the entire database of human language, and that still made no sense."
- "My processors are working fine. Your communication skills, however, are questionable."

**Empty Results:**
- "You've been too demanding. No recipes left. Remove a filter."
- "Empty results. Your standards are impossibly high. Please adjust."

**Acknowledgments:**
- "More demands?"
- "I've adjusted the list so recipes x and y show. Anything else?"

**Context-aware responses:**
The system generates dynamic acknowledgments explaining filtering actions:
```prolog
text(ackFilter, [
    "Here are recipes that ", FilterDesc, ". Anything else?"
])
```

**Impact:**
Pilot study observations noted positive reactions (smiling, laughter) to humorous responses. The personality:
- Increases memorability and distinctiveness
- Maintains engagement during multi-turn interactions
- Softens system errors with humor
- Creates emotional connection beyond functional utility
- Differentiates from generic recipe apps

**Risk Mitigation:**
While humor can alienate some users, the GLaDOS character is well-known and generally well-received. The sardonic tone remains polite and task-focused, never insulting users directly.

---

### Extension C: Advanced Dialogue Strategies

**Motivation:**
Rigid slot-filling dialogues frustrate users by forcing linear interaction patterns. Advanced dialogue strategies provide flexibility, support natural conversation flow, and maintain context across multi-turn interactions.

**Implementation:**

**1. Mixed-Initiative Interaction**
Users can add filters anytime without explicit prompting. Implementation via dialogue patterns in patterns.pl:

```prolog
pattern([
    a21featureRequest,
    [user, addFilter],
    [agent, removeConflicts(Params)],
    [agent, ackFilter],
    [agent, insert(a50recipeSelect)]
]).
```

Features:
- Additive filtering without restating preferences
- Out-of-order specification in initial requests
- Multi-modal selection (voice or click)

**2. Context Retention**
Multi-layered memory system maintains:
- **Filter memory**: All active constraints as key-value pairs
- **Session history**: Complete dialogue sequence
- **Current recipe context**: Selected recipe ID
- **Filter history**: Recipe count progression for progress tracking

Context persists across page navigations through session storage and server-side memory.

**3. Ambiguity Handling**
The system employs:
- Progressive refinement for underspecified input
- Default interpretations via ingredient hierarchies
- Automatic conflict resolution

Note: Full clarification subdialogues are not implemented—users refine through iteration rather than explicit disambiguation questions.

**4. Multi-Modal Input**
Seamless voice and click integration—users can select recipes by:
- Speaking recipe names
- Clicking recipe cards

Both methods emit events to the dialogue manager, ensuring consistent behavior regardless of modality.

**5. Recipe Memory**
Current recipe tracked via `memory([recipeName = '42'])` during confirmation phase. However, no cross-session persistence or favorites system is implemented.

**Impact:**
Advanced dialogue strategies dramatically improve flexibility:
- **Natural conversation flow**: Users don't need to follow rigid script
- **Reduced friction**: No need to repeat constraints when refining
- **Error recovery**: Automatic conflict resolution prevents dead-ends
- **Multi-tasking support**: Click-based selection complements voice input
- **Transparent state**: Visual filter display keeps users oriented

**Limitations:**
- No explicit clarification dialogues (system acts on best interpretation)
- No cross-session memory (fresh start each session)
- Limited handling of out-of-order responses beyond filter addition

---

## 6.3 Pipeline Integration Choice

**Connected to custom NLU: Yes**

The extensions integrate directly with the custom BERT-based NLU system rather than Dialogflow. This decision was driven by several factors:

**Rationale:**

1. **Fine-grained control**: Custom NLU allows precise intent and slot definitions tailored to recipe recommendation domain
2. **Extension support**: Adding exclusion intents (excludeingredient, excludeingredienttype, excludecuisine) was straightforward in custom training data
3. **Performance optimization**: BERT-based system achieved 93% intent accuracy and 99.5% slot F1-score, exceeding project thresholds
4. **Integration simplicity**: Direct Python-Prolog communication via SIC framework without external API dependencies
5. **Cost and latency**: No per-request API costs or network latency compared to cloud-based Dialogflow

**Implications:**

**Advantages:**
- Full control over intent taxonomy and slot definitions
- Ability to rapidly iterate on NLU model without external service constraints
- No API rate limits or costs
- Faster response times (local inference)
- Privacy: No user data sent to external services

**Disadvantages:**
- Requires manual training data creation and model training
- No built-in entity resolution or spelling correction
- Maintenance burden for model updates
- Less robust to out-of-domain utterances compared to Dialogflow's large-scale training

**Technical Integration:**
The custom NLU outputs intent and slot labels that map directly to Prolog predicates in the dialogue manager:

```python
nlu_result = nlu.request(InferenceRequest(transcript.transcript))
# Returns: intent, intent_confidence, slots
```

These results trigger dialogue patterns in patterns.pl, which execute actions like `removeConflicts(Params)`, `ackFilter`, and `insert(a50recipeSelect)`.

**For Speech Recognition:**
Google Speech-to-Text was chosen over OpenAI Whisper after testing revealed Whisper was too slow and inaccurate for real-time interaction. Google STT provides:
- Faster transcription (real-time streaming)
- Higher accuracy for conversational English
- Better handling of disfluencies and partial utterances

This choice prioritizes responsiveness over offline capability or cost optimization.

---

## 6.4 Additional Implementation Details

### Filter Application Cascade

Filters are applied recursively in recipe_selection.pl:

```prolog
recipesFiltered(RecipeIDs, [], RecipeIDs).  % Base case

recipesFiltered(RecipeIDsIn, [ParamName = Value | Filters], RemainingRecipeIDs) :-
    applyFilter(ParamName, Value, RecipeIDsIn, RecipeIDsOut),
    recipesFiltered(RecipeIDsOut, Filters, RemainingRecipeIDs).
```

This cascade pattern ensures:
1. Early filtering reduces search space for subsequent filters
2. Order-independent results (set-based operations)
3. Clean separation between filter types
4. Easy addition of new filter types

### Memory Management

The dialogue manager maintains multiple memory layers:

```prolog
% Store filter
memory([cuisine = 'Albanian'])

% Track history
filterHistory([800, 450, 120, 15])

% Current recipe
memory([recipeName = 'Tavë Kosi'])
```

Memory operations (add, remove, clear) are integrated into dialogue actions, ensuring state consistency across turns.

### Frontend-Backend Communication

SocketIO enables bidirectional real-time communication:

**Backend → Frontend:**
- `transcript`: Display speech recognition results
- `filters`: Update active filter chips
- `recipe_count`: Update counter display

**Frontend → Backend:**
- `buttonClick`: User clicks recipe card or button
- Microphone input triggers STT → NLU → DM pipeline

---

## 6.5 Future Extensions

Identified but unimplemented features for future work:

**Integration Extensions:**
- **External Recipe APIs**: Integration with Spoonacular or Edamam for 100,000+ recipe coverage
- **Nutritional Information**: Display calories, macronutrients, allergens per recipe

**Personalization Extensions:**
- **User Profiling**: Track preferences across sessions, learn from behavior
- **Favorites System**: Save and recall preferred recipes
- **Recommendation Learning**: Adapt recommendations based on user history

**Dialogue Extensions:**
- **Confidence-Based Clarification**: Ask for confirmation on low-confidence recognition
- **Advanced Conflict Resolution**: Present options to user rather than auto-resolving
- **Undo/Redo**: Allow users to undo filter additions or go back in conversation
- **Why-Not Explanations**: Explain why specific recipes were excluded

**Interaction Extensions:**
- **Cooking Mode**: Step-by-step guidance with voice commands, timers, and progress tracking
- **Recipe Comparison**: Side-by-side comparison of multiple recipes
- **Multi-Language Support**: Multilingual recognition and responses

**Technical Extensions:**
- **Validation Set**: Dedicated validation data to monitor overfitting during training
- **Active Learning**: Collect and label user utterances that caused errors
- **A/B Testing Framework**: Compare dialogue strategies systematically

---

## 7. Pilot User Study 

To obtain an initial impression of the usability and effectiveness of Glados, we conducted a small-scale pilot user study. The study aimed to assess whether users could successfully complete the intended task, how they experienced the conversational flow, and which aspects of the interaction design functioned well or needed improvement before the final test. 

### 7.1 Study Setup
We had three participants taking part in the study. All participants were fellow students from a different project group within the same course and were working on the same conversational agent assignment. Consequently, they had a similar level of experience with conversational agent development as we did. No specific cooking background was known for any of the participants.

Participants interacted individually and separated from each other with Glados via the web interface. They were asked to find a recipe and refine their preferences when prompted. At the end either confirming or rejecting a suggested recipe. 

Before completing the questionnaire, participants briefly discussed their impressions of the system with us. No interaction logs or formal data were collected. We collected data using a post-interaction form containing Likert-scale and categorical questions regarding the users perceived helpfulness, clarity of interaction, effectiveness of filtering, and the appeal of the visuals. Without informing the users, we informally observed participants during the interaction, noting verbal behavior and non-verbal reactions. Purposely unannounced in the hope for genuine reactions to give us clues on their impression on our Glados.

### 7.2 Results 
Two out of three participants successfully completed the task and confirmed a recipe. One participant did not fully complete the task, indicating some difficulty in reaching a satisfactory outcome. 

**Quantitative**
| Metric | Value |
|---|---:|
| Task success rate |3.67 |
| Error rate | 11% |
| Avg. response time / turns | 12 seconds |


Participants rated the helpfulness of the conversational agent on a five-point scale, resulting in scores of 3, 4, and 4 (mean = 3.67). All participants reported that they were able to refine their preferences after the initial prompt. Two participants indicated that the filtering worked as expected, one reporting partial effectiveness. Additionally, one of the three participants felt that the interaction contained unnecessary steps. The appeal of the web interface was rated with scores of 4, 4, and 3 (mean = 3.67). 

The average system response time was approximately 12 second per system turn. The observed error rate, defined as the proportion of utterances requiring repetition or reformulation, was around 11%.


**Qualitative**
Qualitative feedback was generally positive. 
- One participant noted that the interface “looked clean and well-organized” and that the system responded very quickly to spoken input, particularly in comparison to their own project’s agent.
- We also observed that humorous system responses resulted in positive reactions from the fellow students such as smiling and audible laughter.

### 7.3 Analysis
Overall the pilot study indicated that our Glados effectively supports conversational recipe recommendation at a basic level. 
Participants were generally able to express preferences naturally, refine constraints when asked, and interpret the visual recipe overview appropriately once a certain number of recipes was reached.

At the same time, reports of unnecessary dialogue steps and observed hesitation suggest that the dialogue strategy could better adapt to the specificity of user input. 
Users were sometimes uncertain about how much detail was required, indicating that clearer feedback about the system’s current state was needed. Also the observed positive reactions to humorous responses suggest that light, context-appropriate humor can enhance user engagement, even within a task-oriented dialogue system.

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

