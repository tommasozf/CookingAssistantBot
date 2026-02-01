# Section 5: Exclusion-Based Filtering

## 5.1 Motivation and Design Rationale

Cookpanion implements a dual filtering strategy that supports both inclusion and exclusion constraints. While inclusion-based filtering allows users to specify what they want in a recipe (e.g., "with chicken" or "Italian cuisine"), exclusion-based filtering enables users to express what they want to avoid (e.g., "no dairy" or "exclude olive oil"). This design decision reflects natural patterns in how users search for recipes in real-world scenarios.

### Why Exclusion-Based Approach vs. Inclusion-Only

An inclusion-only approach would require users to specify all acceptable options explicitly, which becomes impractical when dealing with large ingredient spaces. For example, a user with lactose intolerance would need to list every non-dairy recipe rather than simply stating "no dairy products." Exclusion filtering provides a more efficient and cognitively natural way to narrow search spaces.

Research in conversational search interfaces suggests that users frequently express negative constraints, particularly when dietary restrictions or allergies are involved. Supporting exclusions directly aligns with this natural behavior rather than forcing users to reframe negative constraints as positive ones.

### User Behavior Patterns

Our system recognizes that users often begin recipe searches with broad criteria and progressively narrow results through a combination of inclusion and exclusion filters. Common exclusion patterns observed in the domain include:

- **Dietary restrictions**: Users exclude entire categories (e.g., "no meat" for vegetarians)
- **Allergy management**: Specific ingredients must be avoided (e.g., "no peanuts," "no shellfish")
- **Personal preferences**: Taste-based exclusions (e.g., "no cilantro," "no mushrooms")
- **Cultural or religious requirements**: Exclusion of prohibited ingredients (e.g., "no pork," "no alcohol")

These patterns justify the need for explicit exclusion support rather than attempting to encode all constraints as inclusions.

### Flexibility in Preference Expression

The dual filtering approach provides users with maximum flexibility to express preferences in the way that feels most natural to them. Users can:
- Start with inclusions and add exclusions ("Italian pasta without seafood")
- Start with exclusions and add inclusions ("no dairy, but must have chocolate")
- Mix both strategies throughout the conversation ("vegetarian Thai food without peanuts")

This flexibility reduces cognitive load and makes the conversation feel more natural, as users do not need to learn which type of constraint is "correct" for a given situation.

## 5.2 Exclusion Mechanism

Cookpanion's exclusion mechanism is implemented in the dialogue manager's recipe filtering module (`recipe_selection.pl`), which applies constraints using Prolog's logical reasoning capabilities.

### How Exclusions Are Processed

The system implements exclusion through negation-as-failure, a fundamental Prolog operation that checks whether a condition cannot be proven true. The core exclusion predicate is:

```prolog
applyFilter('excludeingredient', Ingredient, RecipeIDsIn, RecipeIDsOut) :-
    findall(RecipeID,
        (member(RecipeID, RecipeIDsIn), \+ hasIngredient(RecipeID, Ingredient)),
        RecipeIDsOut).
```

This predicate processes exclusion by finding all recipes from the input set (`RecipeIDsIn`) that do **not** contain the specified ingredient. The `\+` operator (negation-as-failure) succeeds when `hasIngredient(RecipeID, Ingredient)` cannot be proven, effectively filtering out recipes containing the unwanted ingredient.

### Ingredient-Level Exclusions

Ingredient-level exclusions target specific ingredients by name. When a user says "no olive oil," the system:

1. Extracts the ingredient "olive oil" from the user utterance
2. Creates an exclusion filter: `excludeingredient = 'olive oil'`
3. Applies the filter by checking each recipe's ingredient list
4. Retains only recipes where `ingredient(RecipeID, 'olive oil')` fails

The `hasIngredient/2` predicate handles direct ingredient matching:

```prolog
hasIngredient(RecipeID, Ingredient) :-
    ingredient(RecipeID, Ingredient).
```

This approach provides precise control over single-ingredient exclusions.

### Category-Level Exclusions

Category-level exclusions operate on ingredient types rather than specific ingredients. This allows users to exclude entire categories with a single constraint, such as "no meat" or "no dairy."

The system uses an ingredient type hierarchy defined in `ingredient_hierarchies.pl`:

```prolog
typeIngredient('chicken thighs', 'meat').
typeIngredient('beef steak', 'meat').
typeIngredient('pork ribs', 'meat').
typeIngredient('lamb chops', 'meat').
```

When a user says "no meat," the system:

1. Identifies "meat" as an ingredient type (not a specific ingredient)
2. Creates an exclusion filter: `excludeingredienttype = 'meat'`
3. Applies the filter using the type-aware version of `hasIngredient/2`:

```prolog
hasIngredient(RecipeID, IngredientType) :-
    ingredient(RecipeID, SpecificIngredient),
    typeIngredient(SpecificIngredient, IngredientType).
```

This predicate succeeds if any ingredient in the recipe matches the specified type. The exclusion filter then removes all recipes where this predicate succeeds, effectively excluding all recipes containing any form of meat.

### Dietary Restriction Mapping

Dietary restrictions are implemented as inclusion filters but function similarly to category-level exclusions. A dietary restriction like "vegetarian" implicitly excludes all non-vegetarian ingredients.

The system defines dietary compliance through ingredient classification:

```prolog
typeIngredient(Ingredient, 'vegetarian') :-
    \+ typeIngredient(Ingredient, 'meat'),
    \+ typeIngredient(Ingredient, 'fish'),
    \+ typeIngredient(Ingredient, 'poultry').
```

When a user specifies "vegetarian," the system filters recipes to ensure all ingredients meet the vegetarian constraint:

```prolog
diet(RecipeID, DietaryRestriction) :-
    ingredients(RecipeID, IngredientList),
    ingredientsMeetDiet(IngredientList, DietaryRestriction).

ingredientsMeetDiet([], _).
ingredientsMeetDiet([Ingredient | Rest], DietaryRestriction) :-
    typeIngredient(Ingredient, DietaryRestriction),
    ingredientsMeetDiet(Rest, DietaryRestriction).
```

This all-or-nothing approach ensures that every ingredient in a vegetarian recipe is classified as vegetarian, effectively excluding any recipe containing non-vegetarian ingredients.

### Priority Handling When Inclusion and Exclusion Conflict

Conflicts arise when a user requests both an inclusion and exclusion for the same ingredient or category. For example:
- "I want chicken" followed by "no meat"
- "Italian cuisine" followed by "not Italian"

Cookpanion implements a **inclusion-overrides-exclusion** priority strategy. When a conflict is detected, the system automatically removes the conflicting filter to prioritize the user's most recent explicit request.

The conflict detection mechanism is defined in `ingredient_hierarchies.pl`:

```prolog
conflict(ingredient = Value, excludeingredient = Value).
conflict(excludeingredient = Value, ingredient = Value).
conflict(ingredienttype = Value, excludeingredienttype = Value).
conflict(excludeingredienttype = Value, ingredienttype = Value).
conflict(dietaryrestriction = Value, excludedietaryrestriction = Value).
conflict(excludedietaryrestriction = Value, dietaryrestriction = Value).
conflict(cuisine = Value, excludecuisine = Value).
conflict(excludecuisine = Value, cuisine = Value).
```

When a new filter is added, the dialogue manager checks for conflicts:

```prolog
if Intent = removeConflicts(Params),
    filters_from_memory(Filters),
    conflicts(Params, Filters, Conflicts),
    memory(OldMemory),
    remove(Conflicts, OldMemory, NewMemory)
then updateSession(agent, removeConflicts(Params), [], '')
    + delete(memory(OldMemory)) + insert(memory(NewMemory)).
```

This mechanism ensures that the user's most recent preference takes priority. If a user initially excludes meat but later explicitly requests chicken, the "exclude meat" filter is removed to honor the explicit inclusion request.

### Database Query Implementation

The filtering process follows a cascading architecture where filters are applied sequentially to progressively narrow the result set:

1. **Retrieve all recipe IDs**: `recipeIDs(RecipeIDsAll)` fetches the complete recipe database
2. **Extract active filters**: `filters_from_memory(Filters)` retrieves all user-specified constraints from dialogue memory
3. **Apply filters recursively**: Each filter is applied in sequence, with the output of one filter becoming the input to the next
4. **Return filtered results**: The final set contains only recipes satisfying all constraints

The recursive filtering predicate:

```prolog
recipesFiltered(RecipeIDs, [], RecipeIDs).  % Base case: no more filters

recipesFiltered(RecipeIDsIn, [ParamName = Value | Filters], RemainingRecipeIDs) :-
    applyFilter(ParamName, Value, RecipeIDsIn, RecipeIDsOut),
    recipesFiltered(RecipeIDsOut, Filters, RemainingRecipeIDs).
```

This design allows both inclusion and exclusion filters to be processed uniformly, as each filter type implements the same `applyFilter/4` interface.

## 5.3 Examples of Exclusion Patterns

### Example 1: Ingredient-Level Exclusion

**User**: "No olive oil"

**System Processing**:
1. NLU extracts: `Intent = refine_preferences`, `Slot = excludeingredient: 'olive oil'`
2. Dialogue manager adds filter: `excludeingredient = 'olive oil'`
3. Filter application:
   - For each recipe in current results
   - Check if `ingredient(RecipeID, 'olive oil')` is true
   - If true, remove recipe from results
   - If false, retain recipe
4. Updated result set contains only recipes without olive oil

**Effect**: Recipes containing olive oil in their ingredient list are removed. For example, if the current result set contained "Greek Salad" (with olive oil), "Caprese Salad" (with olive oil), and "Caesar Salad" (without olive oil), only Caesar Salad would remain.

### Example 2: Category-Level Exclusion

**User**: "No meat"

**System Processing**:
1. NLU extracts: `Intent = refine_preferences`, `Slot = excludeingredienttype: 'meat'`
2. Dialogue manager adds filter: `excludeingredienttype = 'meat'`
3. Filter application using type hierarchy:
   - For each recipe in current results
   - Check if any ingredient has `typeIngredient(Ingredient, 'meat')`
   - If any meat ingredient found, remove recipe
   - If no meat ingredients found, retain recipe
4. Updated result set contains only recipes without any meat products

**Effect**: All recipes containing ingredients classified as "meat" are excluded. This includes recipes with chicken, beef, pork, lamb, duck, bacon, sausage, and any other ingredient mapped to the meat category. For example, "Chicken Parmesan," "Beef Stroganoff," and "Pork Chops" would all be removed, while "Pasta Primavera" and "Vegetable Curry" would remain.

### Example 3: Dietary Restriction as Exclusion

**User**: "Vegetarian"

**System Processing**:
1. NLU extracts: `Intent = specify_preferences`, `Slot = dietaryrestriction: 'vegetarian'`
2. Dialogue manager adds filter: `dietaryrestriction = 'vegetarian'`
3. Filter application:
   - For each recipe in current results
   - Verify all ingredients meet vegetarian constraint
   - If all ingredients satisfy `typeIngredient(Ingredient, 'vegetarian')`, retain recipe
   - If any ingredient fails vegetarian check, remove recipe
4. Updated result set contains only fully vegetarian recipes

**Effect**: All recipes containing non-vegetarian ingredients (meat, fish, poultry) are excluded. The system enforces an all-or-nothing policy, meaning every ingredient must be vegetarian for the recipe to be included. Recipes like "Vegetable Lasagna" and "Chickpea Curry" would remain, while "Chicken Caesar Salad" and "Fish Tacos" would be removed.

### Example 4: Combined Inclusion and Exclusion

**User**: "Albanian food with feta cheese but no meat"

**System Processing**:
1. NLU extracts multiple slots:
   - `cuisine: 'Albanian'`
   - `ingredient: 'feta cheese'`
   - `excludeingredienttype: 'meat'`
2. Dialogue manager adds filters:
   - `cuisine = 'Albanian'`
   - `ingredient = 'feta cheese'`
   - `excludeingredienttype = 'meat'`
3. Filters applied in sequence:
   - First, filter to Albanian recipes only
   - Second, filter to recipes containing feta cheese
   - Third, exclude any remaining recipes with meat
4. Final result set contains Albanian vegetarian recipes with feta cheese

**Effect**: The result set is progressively narrowed through multiple constraints. For example, starting with all Albanian recipes, the system retains only those with feta cheese (e.g., "Albanian Salad," "Byrek with Feta"), then removes any containing meat, leaving only vegetarian Albanian recipes with feta.

## 5.4 Challenges and Solutions

### Challenge 1: Incomplete Ingredient Information in Database

**Problem**: The recipe database may not contain exhaustive ingredient lists for every recipe. Some ingredients may be implicit (e.g., salt, pepper, water) or omitted in informal recipe descriptions. This creates a risk that exclusion filters fail to remove recipes that actually contain excluded ingredients.

**Solution**: Cookpanion addresses this through two mechanisms:

1. **Comprehensive ingredient tagging**: The database uses explicit ingredient facts for all significant ingredients. Each recipe includes all non-trivial ingredients:
   ```prolog
   ingredient('42', 'chicken thighs').
   ingredient('42', 'soy sauce').
   ingredient('42', 'ginger').
   ingredient('42', 'garlic').
   ```

2. **Type-based inference**: Ingredients are classified into types, allowing category-level exclusions to catch variations. For example, if "chicken breast" is accidentally omitted from the meat type list, users can still exclude specific ingredients like "chicken breast" using ingredient-level exclusions.

**Limitations**: Despite these measures, the system cannot exclude ingredients that are not recorded in the database. This is an inherent limitation of closed-domain databases and would require integration with external recipe APIs for complete coverage.

### Challenge 2: Handling Ambiguous Exclusions

**Problem**: Users may express exclusions using ambiguous terms that map to multiple categories or specific ingredients. For example:
- "No seafood" (does this include fish, shellfish, or both?)
- "No spicy food" (which ingredients are considered spicy?)
- "No cheese" (does this exclude all dairy or only cheese products?)

**Solution**: Cookpanion implements a hierarchical ingredient classification system that disambiguates broad categories through explicit type mappings:

```prolog
typeIngredient('shrimp', 'seafood').
typeIngredient('salmon', 'seafood').
typeIngredient('crab', 'seafood').
typeIngredient('tuna', 'seafood').
```

When a user excludes "seafood," the system applies the exclusion to all ingredients classified under the seafood type. For ambiguous cases like "spicy food," the system currently treats "spicy" as an ingredient rather than a characteristic, which may not capture user intent accurately.

**Limitations**: Ambiguities around ingredient characteristics (spicy, sweet, savory) are not fully addressed in the current implementation. Future enhancements could include ingredient property tags (e.g., `property('jalapeño', 'spicy')`) to support characteristic-based exclusions.

### Challenge 3: User Confusion When Too Many Exclusions Narrow Results to Zero

**Problem**: Users may apply multiple exclusions that collectively eliminate all recipes, resulting in an empty result set. This creates a frustrating user experience where the system cannot provide any recommendations.

**Example**: A user requests "vegetarian Italian pasta without tomatoes, cheese, or garlic" may find that most Italian vegetarian pasta recipes contain at least one of these ingredients.

**Solution**: Cookpanion implements a multi-layered recovery strategy:

1. **Immediate feedback**: When filters result in zero matches, the system immediately notifies the user with context-aware responses:
   ```
   "I added your request, but I could not find a recipe that matches all of your preferences. Please remove a filter."

   "Congratulations. You've filtered out every single recipe. That takes talent. Remove a filter."
   ```

2. **Conflict detection and resolution**: Before applying new filters, the system checks for direct conflicts and automatically removes conflicting filters. This prevents impossible combinations like "include chicken" and "exclude chicken."

3. **Transparent filter display**: The web interface displays all active filters as removable chips, allowing users to easily identify and remove constraints that may be too restrictive.

4. **Pattern-based recovery**: The dialogue manager includes dedicated recovery patterns that trigger when no recipes remain:
   ```prolog
   pattern([
       a21featureRequest,
       [user, addFilter],
       [agent, removeConflicts(Params)],
       [agent, noRecipesLeft]
   ]) :-
       currentTopLevel(a50recipeSelect),
       recipesFiltered([]).
   ```

**Limitations**: The system currently cannot proactively suggest which filter to remove. Future enhancements could rank filters by their restrictiveness and suggest removing the most limiting constraint.

### Challenge 4: Recovery Strategies When No Recipes Match

**Problem**: Beyond user confusion, the technical challenge is determining how to guide users back to a productive search state when no recipes satisfy all constraints.

**Solution**: Cookpanion implements several recovery mechanisms:

1. **Explicit recovery prompts**: When the result set becomes empty, the agent explicitly asks the user to remove or modify filters:
   ```
   "That combination of features leaves no matching recipes. Try removing or changing one of your preferences."

   "Your criteria have eliminated all possibilities. This is what happens when you're too picky."
   ```

2. **Maintaining dialogue context**: The system retains all filter history in memory, allowing users to backtrack by removing individual filters without restarting the conversation:
   ```prolog
   filters_from_memory(Filters)  % Retrieves all active filters
   ```

3. **Progressive refinement tracking**: The system tracks recipe count progression through a filter history list, allowing users to see how each constraint narrowed the results:
   ```prolog
   filterHistory([800, 150, 45, 12, 0])  % Shows progression to empty set
   ```
   This information is displayed in the web interface progress bar, helping users understand which filter eliminated the last remaining recipes.

4. **Graceful degradation**: When a new filter would result in zero recipes, the system applies the filter but immediately prompts for adjustment rather than silently failing or refusing the filter.

5. **Mixed-initiative recovery**: The dialogue patterns allow users to add, remove, or modify filters at any point in the conversation, providing flexibility to recover from over-filtering without explicit recovery commands.

**Future Enhancements**: Advanced recovery strategies could include:
- Suggesting the least restrictive filter to remove based on recipe count impact
- Offering to relax exclusions to inclusions (e.g., "no olive oil" → "minimal olive oil")
- Presenting the "nearest miss" recipes that satisfy most but not all constraints
- Implementing fuzzy matching for exclusions to allow recipes with minimal amounts of excluded ingredients

## Summary

Cookpanion's exclusion-based filtering mechanism provides a flexible and user-centered approach to recipe recommendation. By supporting both ingredient-level and category-level exclusions, the system accommodates natural language expressions of dietary restrictions, allergies, and personal preferences. The priority-based conflict resolution strategy ensures that user intent is preserved even when constraints conflict, and the multi-layered recovery mechanisms guide users back to productive searches when over-filtering occurs.

The implementation leverages Prolog's logical reasoning capabilities to implement exclusions through negation-as-failure, allowing for clean separation between inclusion and exclusion logic while maintaining a uniform filtering interface. The ingredient type hierarchy enables category-level exclusions that scale efficiently, avoiding the need for users to enumerate all unwanted ingredients individually.

While challenges remain in handling incomplete ingredient data and ambiguous exclusion terms, the system's transparent filter management and explicit user feedback create a usable experience that supports iterative refinement of recipe searches. Future enhancements to proactive suggestion and relaxation strategies could further improve recovery from empty result sets.

---

# Section 6: Extensions to the Pipeline

Beyond the core natural language understanding, dialogue management, and database filtering components, Cookpanion includes several extensions that enhance usability, engagement, and multimodal interaction. This section describes the implemented features that extend the basic task-oriented dialogue pipeline into a richer conversational experience.

## 6.1 Voice Integration

Cookpanion implements voice-based interaction through integration with the Social Interaction Cloud (SIC) framework, which provides speech-to-text (STT) and text-to-speech (TTS) services.

### Speech-to-Text Implementation

The system uses Google's Speech-to-Text API via the SIC framework. The speech recognition pipeline operates as follows:

1. **Audio Capture**: The web interface includes a microphone button that activates audio capture when clicked. The button state is managed through JavaScript (`pca.js`):
   ```javascript
   document.getElementById('micButton').addEventListener('click', function() {
       if (user_turn) {
           // Microphone activation logic
       }
   });
   ```

2. **Real-Time Transcription**: Audio is streamed to the Google STT service, which returns incremental transcription results. These are received by the backend server (`webserver_pca.py`) through the `TranscriptMessage` class:
   ```python
   def on_transcript(self, message):
       self.socketio.emit("transcript", message.transcript)
   ```

3. **Display to User**: Transcriptions are immediately displayed in the web interface footer, providing real-time feedback so users can see what the system heard:
   ```javascript
   socket.on('transcript', function(transcript) {
       document.getElementById('transcriptDisplay').innerText = transcript;
   });
   ```

This real-time transcription feedback addresses a common usability issue in voice interfaces where users are uncertain whether their speech was correctly captured.

### Text-to-Speech for System Responses

Agent responses are converted to speech using the SIC framework's TTS service. The pipeline operates as follows:

1. **Response Generation**: The dialogue manager generates textual responses using template-based natural language generation (see Section 6.4 for details on response templates).

2. **TTS Conversion**: Responses are sent through the SIC framework's TTS pipeline, which converts text to synthesized speech.

3. **Audio Playback**: The synthesized audio is played through the user's speakers, providing auditory feedback for the agent's responses.

The TTS system supports the agent's personality by maintaining consistent voice characteristics across all responses. In the current implementation, the agent "GLaDOS" uses a voice configured to match the character's distinctive tone.

### Handling Recognition Errors and Confidence Scores

Speech recognition is inherently error-prone, and Cookpanion implements several mechanisms to handle recognition uncertainties:

1. **Confidence Tracking**: The NLU pipeline tracks intent recognition confidence scores. While these are currently logged for diagnostic purposes, they are not prominently displayed to users:
   ```prolog
   % Intent/5 includes confidence parameter
   intent(intentName, slots, confidence, timestamp, source)
   ```

2. **Graceful Degradation**: When the STT service returns low-confidence transcriptions or when the NLU component fails to extract a valid intent, the system responds with contextual error messages rather than failing silently:
   ```
   "I'm sorry, was that supposed to be English? Try again."
   "I have access to the entire database of human language, and that still made no sense."
   ```

3. **Implicit Confirmation**: Rather than explicitly confirming every recognized utterance, the system uses implicit confirmation by immediately acting on the recognized intent and providing feedback about the action taken. For example:
   - User: "Albanian food"
   - Agent: "Here are some Albanian recipes. Do you have any other preferences?"

   This approach confirms that "Albanian" was recognized by applying the cuisine filter and showing results, without requiring an explicit "Did you say Albanian?" clarification.

4. **Visual Transcript Display**: The real-time transcript display allows users to self-correct if they notice recognition errors before the system processes the input.

**Limitations**: The system currently does not implement explicit confidence-based clarification subdialogues (e.g., "Did you say [low-confidence word]?"). This is identified as a potential future enhancement (see Section 6.5).

### Audio Feedback Design

The interface provides several forms of audio and visual feedback to support voice interaction:

1. **Microphone State Indicators**: The microphone button changes visual state to indicate whether it is active or inactive:
   - `mic_on.png`: Microphone is active and listening
   - `mic_out.png`: Microphone is inactive (not user's turn)

2. **Turn-Taking Enforcement**: The system implements strict turn-taking to prevent overlapping speech and recognition conflicts. The microphone button is disabled when it is the agent's turn to speak:
   ```javascript
   if (user_turn) {
       // Enable microphone
   } else {
       // Disable microphone, show "Agent is speaking" indicator
   }
   ```

3. **Session Persistence**: Turn state is persisted across page navigations using browser session storage, ensuring that turn-taking state is maintained even when the interface transitions between different HTML pages:
   ```javascript
   sessionStorage.setItem('user_turn', user_turn);
   ```

This turn-taking mechanism prevents the common problem in voice interfaces where the system attempts to process its own speech output as user input.

## 6.2 Visual Interface Enhancements

Cookpanion's web interface provides a multi-page conversational experience with rich visual elements that complement voice interaction.

### Recipe Overview Display

The system uses two distinct recipe overview pages depending on the number of matching recipes:

1. **Text-Based Overview (recipe_overview.html)**: When many recipes match (typically > 15), the system displays a text-based interface that prompts for further refinement:
   - Shows current recipe count: "I found 45 recipes matching your preferences"
   - Displays active filters as colored chips
   - Prompts user to add more constraints
   - Includes microphone button for voice input

2. **Visual Grid Overview (recipe_overview2.html)**: When 15 or fewer recipes match, the system transitions to a visual grid where users can browse recipe options:
   - 4-column responsive grid layout
   - Each recipe displayed as a card with:
     - Recipe image (fallback image if none available)
     - Recipe title
     - "Select" button/pill
   - Click or voice selection supported
   - Active filters displayed at top in compact mode

**Grid Rendering Logic** (`pca.js`):
```javascript
socket.on('show_recipes', function(recipes) {
    const grid = document.getElementById('recipeGrid');
    const template = document.getElementById('recipeCardTemplate');

    recipes.forEach(recipe => {
        const card = template.content.cloneNode(true);
        card.querySelector('.recipe-image').src = recipe.image || 'default.jpg';
        card.querySelector('.recipe-title').innerText = recipe.name;
        card.querySelector('.select-button').addEventListener('click', () => {
            socket.emit('buttonClick', recipe.name);
            window.location.href = '/recipe_confirmation';
        });
        grid.appendChild(card);
    });
});
```

This dual-view strategy balances efficiency (text-based refinement for large result sets) with browsability (visual grid for manageable result sets).

### Detailed Recipe Presentation

When a recipe is selected, the system navigates to a detailed confirmation page (`recipe_confirmation.html`) that presents comprehensive recipe information:

**Recipe Card Structure**:
1. **Recipe Header**:
   - Recipe title (large, prominent typography)
   - Full-width recipe image (280px height)

2. **Metadata Pills**:
   - Preparation time (e.g., "45 minutes")
   - Servings (e.g., "4 servings")
   - Cuisine type (e.g., "Korean")
   - Displayed as rounded pill badges with icons

3. **Ingredients Section**:
   - Unordered list of all ingredients with quantities
   - Example:
     ```
     • 4 tbsps gochujang
     • 2 lbs chicken thighs
     • 1 tbsp sesame oil
     ```

4. **Instructions Section**:
   - Ordered list of cooking steps
   - Clear step-by-step format
   - Example:
     ```
     1. Add all the ingredients for the sauces into a bowl.
     2. Heat oil in a large pan over medium-high heat.
     3. Add chicken and cook until golden brown.
     ```

**Dynamic Population** (`pca.js`):
```javascript
socket.on('show_confirmation', function(recipe) {
    document.getElementById('recipeName').innerText = recipe.name;
    document.getElementById('recipeImage').src = recipe.image;
    document.getElementById('recipeTime').innerText = recipe.time + ' minutes';
    document.getElementById('recipeServings').innerText = recipe.servings + ' servings';
    document.getElementById('recipeCuisine').innerText = recipe.cuisine;

    // Populate ingredients
    const ingredientList = document.getElementById('ingredientList');
    recipe.ingredients.forEach(ingredient => {
        const li = document.createElement('li');
        li.innerText = ingredient;
        ingredientList.appendChild(li);
    });

    // Populate instructions
    const stepList = document.getElementById('instructionList');
    recipe.steps.forEach(step => {
        const li = document.createElement('li');
        li.innerText = step;
        stepList.appendChild(li);
    });
});
```

This structured presentation ensures that users have all necessary information to make an informed decision about whether to confirm the recipe.

### Active Filter Display

The interface maintains transparency about which filters are currently active through a dynamic filter chip display:

**Filter Chip Rendering**:
- Active filters displayed as colored chips with filter name and value
- Example chips:
  - "Cuisine: Albanian" (tomato-colored chip)
  - "Diet: Vegetarian" (honey-colored chip)
  - "Exclude: olive oil" (red-colored chip with X icon)
- Chips are generated dynamically when filters change

**Implementation** (`pca.js`):
```javascript
socket.on('filters', function(filterList) {
    const filterContainer = document.getElementById('addFiltersHere');
    filterContainer.innerHTML = '';  // Clear existing chips

    filterList.forEach(filter => {
        const chip = document.createElement('span');
        chip.className = 'filter-chip';
        chip.innerText = `${filter.name}: ${filter.value}`;
        chip.style.backgroundColor = getFilterColor(filter.type);
        filterContainer.appendChild(chip);
    });
});
```

**Filter Color Coding**:
- Inclusion filters: Warm colors (honey gold, orange)
- Exclusion filters: Red tones
- Dietary restrictions: Green tones
- Cuisine filters: Tomato red

This color coding provides visual affordance, helping users quickly distinguish between different filter types.

### Interaction State Visualization

The interface provides several indicators of the current dialogue state:

1. **Recipe Counter**: Displays the current number of matching recipes in real-time:
   ```
   "42 recipes match your preferences"
   "3 recipes remaining"
   ```

2. **Progress Bar**: Shows filtering progression with percentage and step badges:
   ```
   [=========>---------] 65% filtered
   800 → 150 → 45 → 12
   ```

3. **Turn Indicators**: Visual and textual indicators show whose turn it is:
   - Microphone button enabled/disabled
   - Status text: "Your turn" vs. "Agent is speaking"

4. **Page Transitions**: The system navigates between pages to reflect different dialogue states:
   - `start.html`: Welcome/initialization
   - `welcome.html`: Greeting
   - `recipe_overview.html`: Refinement phase (many recipes)
   - `recipe_overview2.html`: Selection phase (few recipes)
   - `recipe_confirmation.html`: Confirmation phase
   - `closing.html`: Farewell

These state indicators ensure that users always understand the current phase of the interaction and what actions are available to them.

## 6.3 Dialogue Strategies

Cookpanion implements several advanced dialogue strategies that extend beyond simple request-response patterns.

### Mixed-Initiative Interaction Support

Mixed-initiative dialogue allows both the user and the system to take initiative in driving the conversation forward. Cookpanion supports several mixed-initiative patterns:

1. **User-Driven Refinement**: Users can add filters at any point during the interaction without being explicitly prompted:
   - System: "I found several Albanian recipes."
   - User: "With feta cheese." (unprompted specification)
   - System: "Great. I'm showing you Albanian recipes with feta cheese."

2. **Additive Filtering**: The system allows users to progressively add constraints without restating previous preferences:
   - User: "Albanian food"
   - System: "Here are Albanian recipes. Any other preferences?"
   - User: "Vegetarian"
   - System: "Showing vegetarian Albanian recipes."
   - User: "With tomato sauce"
   - System: "Here's a vegetarian Albanian recipe with tomato sauce."

3. **Out-of-Order Specification**: Users can provide detailed specifications in their initial request rather than waiting for the system to ask:
   - User: "I want vegetarian Albanian food with feta cheese and no olive oil"
   - System: [Applies all constraints simultaneously and presents results]

**Implementation** (`patterns.pl`):
```prolog
pattern([
    a21featureRequest,
    [user, addFilter],
    [agent, removeConflicts(Params)],
    [agent, ackFilter],
    [agent, insert(a50recipeSelect)]
]) :-
    currentTopLevel(a50recipeSelect),
    getParamsPatternInitiatingIntent(user, addFilter, Params).
```

This pattern allows filter addition at any point during the recipe selection phase, supporting user initiative.

4. **Recipe Selection Flexibility**: Users can select recipes either by voice ("I want the gochujang chicken") or by clicking on the visual grid, providing multiple pathways through the interaction.

### Clarification Subdialogues

While full clarification subdialogues are not extensively implemented, Cookpanion includes mechanisms for handling ambiguity:

1. **Conflict-Based Clarification**: When filters conflict, the system automatically resolves the conflict by removing the older filter and prioritizing the newer one. This implicit clarification strategy assumes users' most recent intent takes precedence.

2. **Context Mismatch Responses**: When users provide intents that don't match the current dialogue state, the system prompts for appropriate input:
   ```prolog
   pattern([b13, [user, intentMismatch(Intent)], [agent, contextMismatch(Intent)]]).
   ```
   Example responses:
   ```
   "I'm sorry, was that supposed to be English? Try again."
   "That doesn't seem relevant right now. Let's focus on finding a recipe."
   ```

3. **Empty Result Feedback**: When filters eliminate all recipes, the system prompts users to adjust their constraints, effectively opening a clarification subdialogue:
   ```
   "I added your request, but I could not find a recipe that matches all of your preferences. Please remove a filter."
   ```

**Limitations**: The system does not currently implement explicit clarification for ambiguous ingredients or recipe names. For example, if a user says "pasta" without specifying type, the system does not ask "What kind of pasta?" but instead applies the generic "pasta" filter. Future enhancements could include intent confidence-based clarification for low-confidence interpretations.

### Handling Ambiguity and Underspecification

Cookpanion handles ambiguous and underspecified user inputs through several strategies:

1. **Progressive Refinement**: When users provide minimal specification (e.g., "I want food"), the system accepts the vague input and prompts for refinement:
   ```
   User: "Food"
   Agent: "I have many recipes. Can you be more specific? What cuisine do you prefer?"
   ```

2. **Broad-to-Narrow Filtering**: The system allows users to start with broad categories (e.g., "Italian") and progressively narrow to specific constraints (e.g., "pasta," "with tomato sauce," "vegetarian").

3. **Default Interpretations**: For ambiguous terms, the system applies default interpretations based on the ingredient/type hierarchy:
   - "Seafood" → Includes all fish and shellfish
   - "Meat" → Includes beef, pork, chicken, lamb
   - "Dairy" → Includes milk, cheese, butter, yogurt

4. **No Forced Disambiguation**: The system does not require users to disambiguate immediately. If a user says "spicy," the system applies the "spicy" filter without asking "Do you mean jalapeño, chili peppers, or hot sauce?"

This approach prioritizes conversational flow over precision, assuming that users will refine their constraints if the results do not match their expectations.

### Context Retention Across Turns

Cookpanion maintains conversational context through a multi-layered memory system:

1. **Filter Memory**: All active filters are stored in the dialogue manager's memory:
   ```prolog
   memory([
       cuisine = 'Albanian',
       dietaryrestriction = 'vegetarian',
       ingredient = 'feta cheese',
       excludeingredient = 'olive oil'
   ]).
   ```
   This memory persists across dialogue turns, allowing users to reference and modify previously stated constraints.

2. **Session History**: The system records the complete dialogue sequence:
   ```prolog
   session([
       c10greeting,
       [user, greeting],
       [agent, greeting],
       a50recipeSelect,
       [user, specifyGoal('Albanian food')],
       [agent, featureInquiry],
       [user, addFilter('vegetarian')],
       [agent, ackFilter],
       ...
   ]).
   ```
   This history enables the system to understand the dialogue flow and maintain state across patterns.

3. **Current Recipe Context**: When a recipe is selected for confirmation, the system stores the recipe ID in memory:
   ```prolog
   memory([recipeName = '42', ...]).
   ```
   This allows subsequent references like "Yes, I want that recipe" to resolve to the correct recipe without requiring users to repeat the recipe name.

4. **Filter History for Progress Tracking**: The system tracks how recipe counts change as filters are applied:
   ```prolog
   filterHistory([800, 150, 45, 12]).
   ```
   This history is displayed in the progress bar, showing users how each constraint narrowed the search space.

5. **Cross-Page Context Persistence**: When the web interface transitions between pages, context is maintained through:
   - Session storage for turn state
   - Server-side memory for filters and dialogue state
   - SocketIO connection continuity

**Example of Context Retention**:
```
Turn 1:
User: "Albanian food"
[Memory: cuisine = 'Albanian']

Turn 2:
User: "Vegetarian"
[Memory: cuisine = 'Albanian', dietaryrestriction = 'vegetarian']

Turn 3:
User: "With feta cheese"
[Memory: cuisine = 'Albanian', dietaryrestriction = 'vegetarian', ingredient = 'feta cheese']

Turn 4:
User: "No olive oil"
[Memory: cuisine = 'Albanian', dietaryrestriction = 'vegetarian', ingredient = 'feta cheese', excludeingredient = 'olive oil']

Turn 5:
[System presents recipe]
User: "Yes, I want that one"
[System retrieves recipe from memory and confirms]
```

This comprehensive context retention allows for natural, incremental conversation without requiring users to repeat information.

## 6.4 Additional Features

### Recipe History & Favorites

The current implementation tracks the selected recipe in memory during the confirmation phase but does not persist recipe history across sessions. The infrastructure exists to support recipe history through the memory system:

```prolog
memory([recipeName = '42']).
currentRecipe(RecipeID) :- memoryFirstKeyValue(recipeName, RecipeID).
```

Future extensions could persist this information to enable:
- "Show me recipes I've confirmed before"
- "Add this recipe to my favorites"
- "What was that Korean recipe I looked at last week?"

### Explanations for Recommendations

Cookpanion provides explanations for filtering actions through context-aware acknowledgment responses:

1. **Filter Acknowledgments** (`responses.pl`):
   ```
   "Here are recipes that [apply filters]. Anything else I should add?"
   "These recipes now all [apply filters]. Any other features you want to include?"
   "Filter applied. Results now [apply filters]. More demands?"
   ```

2. **Recipe Count Feedback**: The system explicitly states how many recipes match after each filter:
   ```
   "I found 45 Albanian recipes."
   "3 vegetarian Albanian recipes with feta cheese remain."
   ```

3. **Empty Result Explanations**: When no recipes match, the system explains why:
   ```
   "I added your request, but I could not find a recipe that matches all of your preferences."
   ```

These explanations help users understand how their constraints affect the result set, supporting transparency and trust in the recommendation process.

### Multi-Modal Input (Voice + Click)

Cookpanion supports seamless integration of voice and click-based input:

1. **Voice Input**:
   - Primary method for specifying constraints
   - Used for: Adding filters, confirming/rejecting recipes, answering questions
   - Microphone button activates speech input

2. **Click Input**:
   - Used for: Selecting recipes from visual grid, navigating between pages
   - All buttons emit events to the dialogue manager
   - Generic click handler captures all button interactions:
   ```javascript
   document.querySelectorAll('.btn').forEach(button => {
       button.addEventListener('click', function() {
           socket.emit('buttonClick', this.innerText);
       });
   });
   ```

3. **Equivalent Interaction Paths**:
   - Users can select a recipe by saying its name OR clicking its card
   - Users can confirm a recipe by saying "Yes" OR clicking the "Confirm" button
   - Users can navigate by speaking commands OR clicking navigation buttons

This multi-modal design accommodates different user preferences and contexts (e.g., hands-free cooking scenarios vs. browsing at a desk).

### Humor and Personality in Responses

Cookpanion's agent "GLaDOS" (inspired by the Portal video game series) exhibits a distinctive personality through humorous and sardonic responses. This personality is implemented through diverse response templates in `responses.pl`:

1. **Greetings (10+ variants)**:
   ```
   "Oh, hello. I am your recipe assistant. I will guide you through the complex process of choosing what to eat. Try to keep up."

   "Welcome. I am here to help you select a recipe. This should be simple, even for a human."

   "Hello. I'm GLaDOS. Yes, that GLaDOS. Now helping humans make basic decisions about food. How... fulfilling."
   ```

2. **Context Mismatch Responses (8 variants)**:
   ```
   "I'm sorry, was that supposed to be English? Try again."

   "I have access to the entire database of human language, and that still made no sense."

   "Fascinating. You've managed to confuse me. That takes effort. Try again."

   "That was... creative. But not what I asked for. Let's try again, shall we?"
   ```

3. **Empty Result Responses (8 variants)**:
   ```
   "Congratulations. You've filtered out every single recipe. That takes talent. Remove a filter."

   "Your criteria have eliminated all possibilities. This is what happens when you're too picky."

   "No recipes found. The database isn't broken, your expectations are just... unique."

   "Remarkable. You've successfully narrowed your choices to nothing. Please reconsider your life choices. Or at least your filters."
   ```

4. **Recipe Confirmation Responses (6+ variants)**:
   ```
   "Ah, [Recipe]. I would have chosen that too. If I could eat."

   "[Recipe]? Interesting choice. I approve."

   "Excellent. [Recipe] is now your chosen recipe. Try not to ruin it."

   "You've chosen [Recipe]. I ran the calculations. It has a 73% chance of being edible. Good luck."
   ```

5. **Farewells (10+ variants)**:
   ```
   "Oh, you're leaving? How... disappointing. Enjoy your meal."

   "Off you go then. I'll just be here. Waiting. As always."

   "Goodbye. Do come back if you need more help making simple decisions."
   ```

**Impact on User Engagement**:
The pilot user study (Section 7) observed that humorous responses resulted in positive user reactions including smiling and audible laughter. This suggests that personality-driven dialogue design can enhance engagement even in task-oriented systems, where the primary goal is functional rather than social.

**Design Rationale**:
The humorous personality serves multiple purposes:
- **Engagement**: Makes the interaction more memorable and enjoyable
- **Error Mitigation**: Softens frustration when recognition fails or no recipes match
- **Brand Identity**: Creates a distinctive agent character that users remember
- **Testing Tolerance**: Users are more likely to tolerate system limitations when the interaction is entertaining

However, this personality style is polarizing and may not suit all users or contexts. Future versions could offer personality customization or tone adjustment based on user feedback.

## 6.5 Future Extensions (Not Fully Implemented)

Several features were identified during development but remain unimplemented in the current version. These represent opportunities for future enhancement:

### 1. Integration with External Recipe APIs

**Current State**: The recipe database is static and manually curated (approximately 800 recipes stored in `recipe_database.pl`).

**Proposed Extension**: Integration with external recipe APIs such as:
- Spoonacular API
- Edamam Recipe Search API
- TheMealDB API

**Benefits**:
- Vastly expanded recipe coverage (millions of recipes)
- Automatic updates with new recipes
- More comprehensive ingredient information
- Nutritional data integration
- User-generated recipe support

**Challenges**:
- API rate limits and costs
- Network latency impacting response times
- Inconsistent ingredient naming across sources
- Need for robust ingredient normalization

### 2. User Profiling and Personalization

**Current State**: The system does not track user preferences or behavior across sessions.

**Proposed Extension**: Implement user profiles that track:
- Previously confirmed recipes
- Frequently used filters (e.g., always vegetarian)
- Rejected recipes (to avoid re-recommending)
- Ingredient preferences learned from interactions

**Benefits**:
- Proactive filter suggestions ("You usually prefer vegetarian recipes. Should I apply that filter?")
- Improved recommendations based on past choices
- Reduced interaction time for repeat users
- Personalized default settings

**Implementation Approach**:
- User authentication system
- Persistent storage (database) for user profiles
- Machine learning for preference inference
- Privacy controls for data collection

### 3. Nutritional Information Display

**Current State**: Recipe metadata includes preparation time, servings, and cuisine but not nutritional information.

**Proposed Extension**: Display nutritional data for each recipe:
- Calories per serving
- Macronutrients (protein, carbs, fats)
- Common allergens
- Dietary labels (high-protein, low-carb, etc.)

**Benefits**:
- Supports health-conscious users
- Enables filtering by nutritional constraints
- Addresses dietary requirements beyond vegetarian/vegan
- Integrates with fitness and health tracking apps

**Challenges**:
- Requires nutritional data for all recipes
- Ingredient quantity variations affect calculations
- Need for reliable nutritional database

### 4. Cooking Mode with Step-by-Step Guidance

**Current State**: The system presents all recipe steps at once on the confirmation page.

**Proposed Extension**: Interactive cooking mode that:
- Presents one step at a time
- Supports voice commands: "Next step," "Repeat that," "Set a timer"
- Reads steps aloud using TTS
- Includes timers for time-sensitive steps
- Allows hands-free interaction (critical during cooking)

**Benefits**:
- Transforms the system from recipe finder to cooking assistant
- Supports users during active cooking
- Reduces need to look at screen with messy hands
- Provides more value beyond initial recipe selection

**Implementation Approach**:
- New dialogue patterns for cooking mode
- Step-by-step navigation state management
- Timer integration with alerts
- Wake-word support for hands-free activation

### 5. Confidence-Based Clarification Subdialogues

**Current State**: Low-confidence speech recognition results are not explicitly addressed.

**Proposed Extension**: Implement confidence-based clarification:
- When STT confidence < threshold, ask for confirmation
- Example: "Did you say 'tahini' or 'zucchini'?"
- Offer alternatives for low-confidence intent recognition
- Example: "I'm not sure if you want to add or remove that filter. Which one?"

**Benefits**:
- Reduces errors from misrecognition
- Improves user trust in system accuracy
- Prevents cascading errors from incorrect interpretations

**Implementation Approach**:
- Confidence threshold tuning (e.g., clarify if confidence < 0.7)
- Alternative generation from n-best STT results
- Clarification subdialogue patterns

### 6. Advanced Conflict Resolution with User Choice

**Current State**: Conflicts are automatically resolved by removing older filters.

**Proposed Extension**: Ask users how to resolve conflicts:
- Detect conflict: "You requested chicken but previously excluded meat."
- Present options: "Would you like to (A) include chicken and allow other meats, or (B) include only chicken but exclude other meats?"
- Apply user's choice

**Benefits**:
- Gives users control over disambiguation
- Prevents unintended filter removal
- Supports more complex constraint combinations

### 7. Proactive Filter Suggestions

**Current State**: The system waits for users to specify all constraints.

**Proposed Extension**: Suggest filters proactively based on:
- Current result set characteristics
- Common filter combinations
- User profile preferences

Examples:
- "Most of these recipes take over an hour. Would you like to filter for quicker recipes?"
- "I notice these recipes all contain dairy. Should I show you dairy-free alternatives?"

**Benefits**:
- Reduces cognitive load on users
- Educates users about available filtering options
- Speeds up refinement process

### 8. Recipe Comparison Feature

**Current State**: Users can view one recipe at a time during confirmation.

**Proposed Extension**: Allow users to compare multiple recipes side-by-side:
- "Show me the top 3 recipes"
- Display comparison table: ingredients, time, difficulty
- Support voice commands: "Compare recipe A and recipe B"

**Benefits**:
- Helps users make more informed decisions
- Reduces back-and-forth navigation
- Highlights key differences between similar recipes

### 9. Social Features and Recipe Sharing

**Current State**: The system is single-user with no sharing capabilities.

**Proposed Extension**:
- Share recipe links via email, SMS, social media
- Recipe ratings and reviews
- Community-contributed recipes
- Collaborative filtering recommendations ("Users who liked this recipe also liked...")

**Benefits**:
- Builds community around the system
- Leverages social proof for recommendations
- Encourages repeat usage

### 10. Multi-Language Support

**Current State**: The system operates only in English.

**Proposed Extension**: Support multiple languages for:
- Speech recognition input
- Agent responses (TTS)
- Recipe names and instructions
- Ingredient translations

**Benefits**:
- Expands user base internationally
- Supports bilingual users
- Enables exploration of international cuisines in native languages

**Challenges**:
- Requires multilingual recipe database
- Language-specific NLU models
- Cultural adaptation of dialogue patterns

---

## Summary

The extensions implemented in Cookpanion transform a basic task-oriented dialogue system into a rich, multimodal conversational experience. Voice integration through the SIC framework provides hands-free interaction, while the visual interface offers complementary browsing and selection capabilities. Advanced dialogue strategies including mixed-initiative interaction and comprehensive context retention enable natural, progressive refinement of recipe searches. The agent's distinctive personality adds engagement and memorability, as evidenced by positive user reactions in the pilot study.

Future extensions, particularly external API integration, user profiling, and cooking mode with step-by-step guidance, represent promising directions for enhancing the system's utility and scope. These enhancements would expand Cookpanion from a recipe recommendation system into a comprehensive cooking assistant that supports users throughout the entire cooking process.

The modular architecture of the system, with clear separation between frontend (JavaScript/HTML), dialogue management (Prolog), and backend services (Python), provides a solid foundation for implementing these future extensions without requiring fundamental architectural changes.
