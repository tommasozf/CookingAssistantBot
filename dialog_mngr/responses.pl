%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Responses when a flag has been set for a button.					%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% responses for NEW dialog agent 		   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

flagResponse('mic', 'Please press Start first') :- flag('mic'), waitingForEvent('start').
flagResponse('mic', 'I am already listening') :-
	flag('mic'), listening.
% We might have just stopped listening but still waiting for results from intention
% detection; so case above does not apply but we still need user to be patient. Order of
% these rules therefore is also important.
%flagResponse('mic', 'Wait a second') :-
%	flag('mic'), waitingForEvent('IntentDetectionDone'). % WAIT A SECOND BUG
flagResponse('mic', "Please, I'm talking") :-
	flag('mic'), talking.
flagResponse('mic', 'Not available right now') :- flag('mic'), not(waitingForEvent(_)).
% In all other cases, flags generate an 'empty' response.
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
% We use top level dialog context, e.g.:
% - greeting (c10)
% - recipe selection (a50recipeSelect)
% - recipe choice confirmation (a50recipeConfirm)
% - closing (c40)
text_generator(Intent, SelectedText) :-
	currentTopLevel(PatternId),
	findall(Text, text(PatternId, Intent, Text), Texts),
	random_select(SelectedText, Texts, _).

% Text generator that does not take dialog context into account.
text_generator(Intent, SelectedText) :-
	findall(Text, text(Intent, Text), Texts), random_select(SelectedText, Texts, _).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Scripted text and phrases for ** GENERIC ** intents (sorted on intent name)		%%%
%%% Text is only provided for those intents that the agent will generate (use). 	%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Intent: appreciationReceipt


% Intent: contextMismatch(Intent)


% Intent: describeCapability


% Intent: farewell
text(farewell, "Goodbye! Bon appetit.").
text(farewell, "See you later! Enjoy your meal.").
text(farewell, "Bye! Hope you have fun cooking.").
text(farewell, "Take care! Let me know if you need any more recipes.").
text(farewell, "Farewell! Happy cooking.").


% Intent: greeting
text(greeting, "Hey there! I am your personal recipe assistant. I will help you come up with a recipe for whatever you want to eat.").

% Intent: paraphraseRequest


% Intent: selfIdentification (for self-identification of the agent)
text(selfIdentification, Text) :- agentName(Name),
string_concat("My name is", Name, Text).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Scripted text and phrases for ** DOMAIN SPECIFIC ** intents (sorted on intent name)	%%%
%%% Text is only provided for those intents that the agent will generate (use). 	%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Intent: ackFilter (acknowledge filters added; there are recipes that satisfy all filters)

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("Here are recipes that ", TxtPart2, Txt1),
	string_concat(Txt1, ". Anything else I should add?", Txt).

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("Okay, I filtered the recipes so that they ", TxtPart2, Txt1),
	string_concat(Txt1, ". Would you like to add another preference?", Txt).

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("These recipes now all ", TxtPart2, Txt1),
	string_concat(Txt1, ". Any other features you want to include?", Txt).


% Intent: featureInquiry

% Intent: featureInquiry
% Scenario 1: Huge list (> 800). Prompt for broad preferences.
text(featureInquiry, "What kind of recipe would you like?") :-
    recipesFiltered(Recipes), 
    length(Recipes, N), 
    N > 800.

% Scenario 2: Moderate list (16-800). 
% Prompt for specific filters.
text(featureInquiry, "What other preference would you like to add?") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    N > 15, N =< 800,
    not(memoryKeyValue('show', 'true')).

% Scenario 3: Empty list (0). 
% Tell user they over-filtered.
text(featureInquiry, "There are no recipes, please remove further requirements.") :-
    recipesFiltered([]).

% Scenario 4: Small list (1-15) OR User forced 'show'.
% Present the results.
text(featureInquiry, "Here are some recipes that fit your requirements.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    ( (N > 0, N =< 15) ; memoryKeyValue('show', 'true') ).


% Intent: featureRemovalRequest

text(featureRemovalRequest,
     "Can you have a look again and remove one of your recipe requirements?").


% Intent: noRecipesLeft

text(noRecipesLeft,
     "I added your request, but I could not find a recipe that matches all of your preferences. Please remove a filter.") :-
	recipesFiltered([]).

text(noRecipesLeft,
     "Unfortunately, there are no recipes left that satisfy all your requirements. You may want to remove one of the filters.") :-
	recipesFiltered([]).

text(noRecipesLeft,
     "That combination of features leaves no matching recipes. Try removing or changing one of your preferences.") :-
	recipesFiltered([]).



% Intent: pictureGranted
text(pictureGranted, "OK. Here is a list of recipes that you can choose from.").

% Intent: pictureNotGranted
text(pictureNotGranted, "Sorry, there are still too many recipes left to show them all. Please add more preferences.").


% Intent: recipeChoiceReceipt (acknowledge user's choice of recipe)

text(recipeChoiceReceipt, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat(Name, " is a great choice!", Text).

% Intent: recommend (a recipe)
text(recommend, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("How about ", Name, Part1),
    string_concat(Part1, "?", Text).


% Intent: recipeCheck

% Ask user to confirm the specific recipe currently in memory.
text(recipeCheck, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Can you confirm ", Name, Part1),
    string_concat(Part1, " is the recipe you would like to cook?", Text).

% Intent: specifyGoal (asking a user about recipe features they are looking for)
text(specifyGoal, "What kind of recipe are you looking for today?").
text(specifyGoal, "What would you like to cook today?").
text(specifyGoal, "Do you have anything in mind for today\'s meal?").


text(clearMemory, ".").
