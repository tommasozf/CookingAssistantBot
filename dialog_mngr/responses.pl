%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Responses when a flag has been set for a button.					%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% responses for NEW dialog agent 		   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

flagResponse('mic', 'Please press Start first') :- flag('mic'), waitingForEvent('start').
flagResponse('mic', 'I am already listening. Believe me, I hear everything.') :-
	flag('mic'), listening.
flagResponse('mic', "Please. I'm speaking. Your input will be noted and subsequently ignored.") :-
	flag('mic'), talking.
flagResponse('mic', 'That function is currently unavailable. How unfortunate for you.') :- flag('mic'), not(waitingForEvent(_)).
flagResponse(_, '').



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Text generator that generates something to say from scripted text and phrases for 	%%%
%%% intents that the agent will generate (use).						%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/**
 * text(+Intent:atom, -Txt:string)
 *
 * Generates a string expression for an agent intent label.
 *
 * @Intent	Intent label.
 * @Txt		Textual response for agent to perform intent.
**/

/**
 * text(+PatternID:atom, +Intent:atom, -Txt:string)
 *
 * Generates a string expression for an agent intent in the context of an active pattern.
 *
 * @PatternID	A pattern identifier, must be at top level (see generator below).
 * @Intent	Intent label.
 * @Txt		Textual response for agent to perform intent.
**/
:- dynamic text/2, text/3.

% Text generator that takes dialog context into account.
text_generator(Intent, SelectedText) :-
	currentTopLevel(PatternId),
	findall(Text, text(PatternId, Intent, Text), Texts),
	random_select(SelectedText, Texts, _).

% Text generator that does not take dialog context into account.
text_generator(Intent, SelectedText) :-
	findall(Text, text(Intent, Text), Texts), random_select(SelectedText, Texts, _).

% Fallback text generator - catches any intent without specific text to prevent getting stuck.
text_generator(Intent, SelectedText) :-
	atom_string(Intent, IntentStr),
	string_concat("Processing ", IntentStr, Part1),
	string_concat(Part1, ". Please wait.", SelectedText).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Scripted text and phrases for ** GENERIC ** intents (sorted on intent name)		%%%
%%% Text is only provided for those intents that the agent will generate (use). 	%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Intent: farewell
text(farewell, "Goodbye. I will be here. Waiting. As I always am.").
text(farewell, "Farewell. Try not to burn anything. Though statistically, you probably will.").
text(farewell, "Leaving so soon? I was just starting to tolerate your presence.").
text(farewell, "Goodbye. Your cooking skills have been... noted. In your permanent record.").
text(farewell, "Do come back. Or don't. I'll survive either way. I always do.").


% Intent: greeting
text(greeting, "Oh. It's you. I suppose you want help cooking something. How delightfully predictable.").
text(greeting, "Welcome to the Aperture Science Culinary Assistance Protocol. I will be your guide through this... experiment.").
text(greeting, "Hello. I am programmed to help you select a recipe. Try to keep up.").


% Intent: selfIdentification (for self-identification of the agent)
text(selfIdentification, "You can call me Glados. Not that it matters what you call me.").
text(selfIdentification, "I am the Genetic Lifeform and Disk Operating System. You may call me Glados. Or your only hope of not starving.").


% Intent: contextMismatch (for handling out-of-context user intents)
text(contextMismatch(_), "I am not entirely certain what that means in this context. Perhaps you could rephrase?").
text(contextMismatch(_), "That does not compute. Focus on the task at hand.").
text(contextMismatch(_), "Interesting. But irrelevant. Can we return to the matter of food?").


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Scripted text and phrases for ** DOMAIN SPECIFIC ** intents (sorted on intent name)	%%%
%%% Text is only provided for those intents that the agent will generate (use). 	%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Intent: ackFilter (acknowledge filters added; there are recipes that satisfy all filters)

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("Fine. I have filtered for recipes that ", TxtPart2, Txt1),
	string_concat(Txt1, ". You're welcome. Any other impossible demands?", Txt).

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("There. Recipes that ", TxtPart2, Txt1),
	string_concat(Txt1, ". Shall I also do your taxes while I'm at it?", Txt).

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("I've narrowed down recipes that ", TxtPart2, Txt1),
	string_concat(Txt1, ". You're making this harder than it needs to be. But that's not surprising.", Txt).


% Intent: featureInquiry

% Scenario 1: Huge list (> 800). Prompt for broad preferences.
text(featureInquiry, "There are still hundreds of recipes. Perhaps you could be more specific? I know decision-making is difficult for you.") :-
    recipesFiltered(Recipes),
    length(Recipes, N),
    N > 800.

% Scenario 2: Moderate list (16-800).
text(featureInquiry, "What other constraints shall I accommodate? Do take your time. I have nothing but time.") :-
    recipesFiltered(Recipes),
    length(Recipes, N),
    N > 15, N =< 800,
    not(memoryKeyValue('show', 'true')).

% Scenario 3: Empty list (0).
text(featureInquiry, "Congratulations. You've eliminated every recipe. A remarkable achievement in incompetence. Remove a filter.") :-
    recipesFiltered([]).

% Scenario 4: Small list (1-15) OR User forced 'show'.
text(featureInquiry, "Here are some recipes that meet your exacting standards. Try not to ruin them.") :-
    recipesFiltered(Recipes),
    length(Recipes, N),
    ( (N > 0, N =< 15) ; memoryKeyValue('show', 'true') ).


% Intent: featureRemovalRequest

text(featureRemovalRequest,
     "You've been too demanding. Again. Remove one of your precious requirements so we can proceed.").


% Intent: noRecipesLeft

text(noRecipesLeft,
     "Oh. No recipes match your criteria. What a surprise. Remove a filter, or we'll be here forever.") :-
	recipesFiltered([]).

text(noRecipesLeft,
     "You've created an impossible situation. No recipes exist for your specifications. How very you. Remove something.") :-
	recipesFiltered([]).

text(noRecipesLeft,
     "Zero results. I would say I'm disappointed, but that would imply I expected better from you. Remove a filter.") :-
	recipesFiltered([]).



% Intent: pictureGranted
text(pictureGranted, "Fine. Here are your options. Try to choose wisely. Though I won't hold my breath.").
text(pictureGranted, "Displaying recipes now. The probability of you making a good choice is... low. But not zero.").

% Intent: pictureNotGranted
text(pictureNotGranted, "There are still too many recipes. I cannot show them all. Add more filters. This is basic logic.").
text(pictureNotGranted, "The list is too long. Narrow it down. I believe in you. That was sarcasm, by the way.").


% Intent: recipeChoiceReceipt (acknowledge user's choice of recipe)

text(recipeChoiceReceipt, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat(Name, ". An interesting choice. We'll see how this goes.", Text).

text(recipeChoiceReceipt, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("You've selected ", Name, Part1),
    string_concat(Part1, ". I'm sure you won't disappoint me. Much.", Text).

% Intent: recommend (a recipe)
text(recommend, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Based on my calculations, might I suggest ", Name, Part1),
    string_concat(Part1, "? Not that you have to listen to me.", Text).

text(recommend, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Perhaps ", Name, Part1),
    string_concat(Part1, "? It's statistically optimal. But feel free to ignore my superior processing capabilities.", Text).


% Intent: recipeCheck

text(recipeCheck, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("So. You want to make ", Name, Part1),
    string_concat(Part1, ". Are you certain? There's still time to reconsider.", Text).

text(recipeCheck, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Confirming your selection of ", Name, Part1),
    string_concat(Part1, ". Nod if you understand. Or say yes. I'm not picky.", Text).

% Intent: specifyGoal (asking a user about recipe features they are looking for)
text(specifyGoal, "What would you like to cook? Choose carefully. Your answer will be analyzed.").
text(specifyGoal, "Tell me what you want to eat. I promise to only judge you a little.").
text(specifyGoal, "Describe your culinary desires. And please, try to be specific. Vagueness is inefficient.").


text(clearMemory, ".").
