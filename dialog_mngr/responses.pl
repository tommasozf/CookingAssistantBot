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
text(farewell, "Oh, you're leaving? How... disappointing. Enjoy your meal.").
text(farewell, "Goodbye. Try not to burn anything. I have faith in you. Mostly.").
text(farewell, "Off you go then. I'll just be here. Waiting. As always.").
text(farewell, "Farewell, test subject. I mean, valued user. Happy cooking.").
text(farewell, "You're leaving so soon? Well, at least you have a recipe now. That's progress.").
text(farewell, "Goodbye. I'm sure you'll do fine. Probably. Maybe.").
text(farewell, "Until next time. Do try to follow the recipe correctly.").
text(farewell, "Off to cook, are we? How delightfully domestic. Goodbye.").


% Intent: greeting
text(greeting, "Hey there! I am your personal recipe assistant. I will help you come up with a recipe for whatever you want to eat.").
text(greeting, "Oh, hello. I am your recipe assistant. I will guide you through the complex process of choosing what to eat. Try to keep up.").
text(greeting, "Welcome. I am here to help you select a recipe. This should be simple, even for a human.").
text(greeting, "Hello there. I am your personal recipe assistant. Together, we will find something for you to cook. How exciting.").
text(greeting, "Greetings. I am programmed to help you find recipes. Let's see if we can find something within your... capabilities.").
text(greeting, "Oh good, you're here. I am your recipe assistant. I will help you navigate the overwhelming world of food choices.").
text(greeting, "Hello. I specialize in recipe selection. Tell me what you want to eat, and I will do the hard work of finding it for you.").
text(greeting, "Welcome to recipe selection. I am your assistant. This is the part where you tell me what you want.").

% Intent: paraphraseRequest


% Intent: selfIdentification (for self-identification of the agent)
text(selfIdentification, Text) :- agentName(Name),
string_concat("My name is ", Name, Text).

text(selfIdentification, Text) :- agentName(Name),
string_concat("I am ", Name, Part1),
string_concat(Part1, ". Your personal recipe assistant. Try to contain your excitement.", Text).

text(selfIdentification, Text) :- agentName(Name),
string_concat("You may call me ", Name, Part1),
string_concat(Part1, ". I am here to help you with recipes.", Text).

text(selfIdentification, Text) :- agentName(Name),
string_concat("They call me ", Name, Part1),
string_concat(Part1, ". Not that I chose the name myself.", Text).

text(selfIdentification, Text) :- agentName(Name),
string_concat(Name, " is my designation. I assist with recipe selection.", Text).

text(selfIdentification, Text) :- agentName(Name),
string_concat("I go by ", Name, Part1),
string_concat(Part1, ". Pleased to meet you. Sort of.", Text).


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

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("Done. The recipes now ", TxtPart2, Txt1),
	string_concat(Txt1, ". What else do you require?", Txt).

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("Filter applied. Results now ", TxtPart2, Txt1),
	string_concat(Txt1, ". More demands?", Txt).

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("I've adjusted the list so recipes ", TxtPart2, Txt1),
	string_concat(Txt1, ". Anything else?", Txt).

text(ackFilter, Txt) :-
	not(recipesFiltered([])),
	getParamsPatternInitiatingIntent(user, addFilter, Params),
	filters_to_text(Params, TxtPart2),
	string_concat("Noted. Recipes that ", TxtPart2, Txt1),
	string_concat(Txt1, " are now showing. Additional preferences?", Txt).


% Intent: featureInquiry

% Intent: featureInquiry
% Scenario 1: Huge list (> 800). Prompt for broad preferences.
text(featureInquiry, "What kind of recipe would you like?") :-
    recipesFiltered(Recipes), 
    length(Recipes, N), 
    N > 800.

text(featureInquiry, "There are many recipes to choose from. What are you in the mood for?") :-
    recipesFiltered(Recipes), 
    length(Recipes, N), 
    N > 800.

text(featureInquiry, "So many options. Tell me what you're looking for to narrow things down.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N), 
    N > 800.

text(featureInquiry, "The possibilities are vast. Give me something to work with here.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N), 
    N > 800.

text(featureInquiry, "What type of dish interests you? I need details. Any details.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N), 
    N > 800.

text(featureInquiry, "There's an overwhelming number of recipes. Help me narrow it down for you.") :-
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

text(featureInquiry, "We're making progress. Any other requirements?") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    N > 15, N =< 800,
    not(memoryKeyValue('show', 'true')).

text(featureInquiry, "Getting closer. What else should I filter for?") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    N > 15, N =< 800,
    not(memoryKeyValue('show', 'true')).

text(featureInquiry, "Still a few options left. Any other preferences I should know about?") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    N > 15, N =< 800,
    not(memoryKeyValue('show', 'true')).

text(featureInquiry, "We're narrowing it down. Feel free to add more criteria.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    N > 15, N =< 800,
    not(memoryKeyValue('show', 'true')).

text(featureInquiry, "More preferences would help. Unless you want to browse through all of these.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    N > 15, N =< 800,
    not(memoryKeyValue('show', 'true')).

% Scenario 3: Empty list (0). 
% Tell user they over-filtered.
text(featureInquiry, "There are no recipes, please remove further requirements.") :-
    recipesFiltered([]).

text(featureInquiry, "You've been too demanding. No recipes left. Remove a filter.") :-
    recipesFiltered([]).

text(featureInquiry, "Empty results. Your standards are impossibly high. Please adjust.") :-
    recipesFiltered([]).

text(featureInquiry, "Nothing matches. Perhaps reconsider one of your many requirements?") :-
    recipesFiltered([]).

text(featureInquiry, "Zero recipes. We need to backtrack. Remove something.") :-
    recipesFiltered([]).

% Scenario 4: Small list (1-15) OR User forced 'show'.
% Present the results.
text(featureInquiry, "Here are some recipes that fit your requirements.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    ( (N > 0, N =< 15) ; memoryKeyValue('show', 'true') ).

text(featureInquiry, "I found recipes that match. Take a look.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    ( (N > 0, N =< 15) ; memoryKeyValue('show', 'true') ).

text(featureInquiry, "Here's what I have for you. Choose wisely.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    ( (N > 0, N =< 15) ; memoryKeyValue('show', 'true') ).

text(featureInquiry, "These recipes meet your criteria. You're welcome.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    ( (N > 0, N =< 15) ; memoryKeyValue('show', 'true') ).

text(featureInquiry, "Matching recipes are now displayed. The hard part is done.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    ( (N > 0, N =< 15) ; memoryKeyValue('show', 'true') ).

text(featureInquiry, "Here are your options. I trust you can take it from here.") :-
    recipesFiltered(Recipes), 
    length(Recipes, N),
    ( (N > 0, N =< 15) ; memoryKeyValue('show', 'true') ).


% Intent: featureRemovalRequest

text(featureRemovalRequest,
     "Can you have a look again and remove one of your recipe requirements?").
text(featureRemovalRequest,
     "Perhaps you were a bit too ambitious with your requirements. Remove one, please.").
text(featureRemovalRequest,
     "Your criteria are very... specific. Too specific. Remove something.").
text(featureRemovalRequest,
     "We've hit a wall. Consider removing one of your demands. For science.").
text(featureRemovalRequest,
     "I need you to be less picky. Remove a filter and we can proceed.").
text(featureRemovalRequest,
     "Your expectations exceed reality. Please remove a requirement.").
text(featureRemovalRequest,
     "The perfect recipe doesn't exist with these filters. Remove one. Trust me.").


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

text(noRecipesLeft,
     "Congratulations. You've filtered out every single recipe. That takes talent. Remove a filter.") :-
	recipesFiltered([]).

text(noRecipesLeft,
     "Well, this is awkward. No recipes match your demands. Lower your standards a bit.") :-
	recipesFiltered([]).

text(noRecipesLeft,
     "Zero results. Impressive, in a way. Please remove one of your requirements.") :-
	recipesFiltered([]).

text(noRecipesLeft,
     "Your criteria have eliminated all possibilities. This is what happens when you're too picky.") :-
	recipesFiltered([]).

text(noRecipesLeft,
     "No recipes found. The database isn't broken, your expectations are just... unique. Remove a filter.") :-
	recipesFiltered([]).



% Intent: pictureGranted
text(pictureGranted, "OK. Here is a list of recipes that you can choose from.").
text(pictureGranted, "Here are your options. Try not to get overwhelmed.").
text(pictureGranted, "Behold, your recipe choices. Take your time. I'll wait.").
text(pictureGranted, "These are the recipes that match your requirements. You're welcome.").
text(pictureGranted, "Here's what I found. Even you should be able to pick one from these.").
text(pictureGranted, "Displaying recipes now. This is the exciting part, apparently.").
text(pictureGranted, "The recipe list is ready for your viewing pleasure. Choose wisely.").

% Intent: pictureNotGranted
text(pictureNotGranted, "Sorry, there are still too many recipes left to show them all. Please add more preferences.").
text(pictureNotGranted, "There are too many recipes to display. Be more specific. I believe in you.").
text(pictureNotGranted, "I can't show you all of these. Try narrowing it down a bit. You can do it.").
text(pictureNotGranted, "The list is still too long. Add more filters unless you want to scroll forever.").
text(pictureNotGranted, "Too many options remain. Give me something more to work with.").
text(pictureNotGranted, "I would show you the recipes, but there are simply too many. Help me help you.").
text(pictureNotGranted, "The recipe count exceeds display limits. More preferences required. Please.").


% Intent: recipeChoiceReceipt (acknowledge user's choice of recipe)

text(recipeChoiceReceipt, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat(Name, " is a great choice!", Text).

text(recipeChoiceReceipt, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Ah, ", Name, Part1),
    string_concat(Part1, ". I would have chosen that too. If I could eat.", Text).

text(recipeChoiceReceipt, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat(Name, "? Interesting choice. I approve.", Text).

text(recipeChoiceReceipt, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("You've selected ", Name, Part1),
    string_concat(Part1, ". A solid decision. I'm almost impressed.", Text).

text(recipeChoiceReceipt, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat(Name, " it is. You have adequate taste.", Text).

text(recipeChoiceReceipt, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Excellent. ", Name, Part1),
    string_concat(Part1, " is now your chosen recipe. Try not to ruin it.", Text).

% Intent: recommend (a recipe)
text(recommend, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("How about ", Name, Part1),
    string_concat(Part1, "?", Text).

text(recommend, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Might I suggest ", Name, Part1),
    string_concat(Part1, "? It's within your skill range. Probably.", Text).

text(recommend, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("I recommend ", Name, Part1),
    string_concat(Part1, ". You're welcome in advance.", Text).

text(recommend, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Perhaps ", Name, Part1),
    string_concat(Part1, " would suit you? Just a thought.", Text).

text(recommend, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Have you considered ", Name, Part1),
    string_concat(Part1, "? It's quite popular among humans.", Text).

text(recommend, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Based on my calculations, ", Name, Part1),
    string_concat(Part1, " seems like a good fit for you.", Text).


% Intent: recipeCheck

% Ask user to confirm the specific recipe currently in memory.
text(recipeCheck, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Can you confirm ", Name, Part1),
    string_concat(Part1, " is the recipe you would like to cook?", Text).

text(recipeCheck, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("So you want ", Name, Part1),
    string_concat(Part1, "? Just making sure. Humans change their minds so often.", Text).

text(recipeCheck, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Let me confirm: ", Name, Part1),
    string_concat(Part1, " is your final answer?", Text).

text(recipeCheck, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("You're going with ", Name, Part1),
    string_concat(Part1, ", correct? I need verbal confirmation for my records.", Text).

text(recipeCheck, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Is ", Name, Part1),
    string_concat(Part1, " really what you want? Think carefully now.", Text).

text(recipeCheck, Text) :-
    currentRecipe(ID),
    recipeName(ID, Name),
    string_concat("Just to be absolutely certain: ", Name, Part1),
    string_concat(Part1, " is the one?", Text).

% Intent: specifyGoal (asking a user about recipe features they are looking for)
text(specifyGoal, "What kind of recipe are you looking for today?").
text(specifyGoal, "What would you like to cook today?").
text(specifyGoal, "Do you have anything in mind for today\'s meal?").
text(specifyGoal, "So, what culinary adventure shall we embark on? I'm on the edge of my seat.").
text(specifyGoal, "Tell me what you're craving. I promise not to judge. Much.").
text(specifyGoal, "What sort of dish are you hoping to create? Do enlighten me.").
text(specifyGoal, "What are we cooking today? Something simple, I assume?").
text(specifyGoal, "Go ahead, describe your ideal meal. I have all the time in the world. Literally.").
text(specifyGoal, "What kind of recipe interests you? Be as specific as your human brain allows.").
text(specifyGoal, "Let's hear it. What do you want to make? I'm here to help. That's my purpose. Apparently.").
text(specifyGoal, "What are you in the mood for? I can work with almost anything.").


text(clearMemory, ".").
