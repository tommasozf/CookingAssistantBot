%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 	Helper predicates for the conversion of atoms and input values			%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% convert_to_int(+Input, -Int)
% Convert an atom or float (e.g. 9.0 received as entity from DialogFlow) to an integer.
convert_to_int(Input, Int) :- atom(Input), atom_number(Input, Float), Int is integer(Float).
convert_to_int(Input, Int) :- number(Input), Int is integer(Input).

% convert to string
convert_to_string(Input, String) :- atom(Input), atom_string(Input, String).
convert_to_string(Input, String) :- string(Input), String = Input.
convert_to_string(Input, String) :- number(Input), number_string(Input, String).
convert_to_string(Input, String) :- is_list(Input), list_to_string(Input, String).

% duration_to_min(+Duration, -Minutes) 
% Convert duration (e.g., [amount = 2, unit = hour]) to minutes so it can be matched to the
% database. DialogFlow also has units for "wk": week, "mo": month, "yr": year, "decade",
% and "century" which are not handled here; NOTE: if any of these units are used, the agent
% will get stuck!
duration_to_min(Duration, Minutes)
	:- member('amount' = A, Duration), member('unit' = Unit, Duration),
		convert_to_int(A, Amount), 
		duration_to_min(Amount, Unit, Minutes).
duration_to_min(Amount, 's', Minutes) :- Minutes is div(Amount, 60).
duration_to_min(Amount, 'min', Amount).
duration_to_min(Amount, 'h', Minutes) :- Minutes is Amount*60.
duration_to_min(Amount, 'day', Minutes) :- Minutes is Amount*60*24.

/**
 *
**/
list_to_string([], "").
list_to_string([Input], String) :- convert_to_string(Input, String).
list_to_string([Input1, Input2 | List], String) :- 
	convert_to_string(Input1, Str1), 
	list_to_string([Input2 | List], Str2),
	string_concat(Str1, " and ", Str3),
	string_concat(Str3, Str2, String).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 	Helper predicates for the changing case of strings				%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% downcase_values(+Params, -DownCaseParams)
% This predicate downcases the input values from the user so they can be matched to the database.
downcase_values([], []).
downcase_values([Key=Value | Rest], [Key=DownValue | DownRest]) :-
	downcase_atom(Value, DownValue), downcase_values(Rest, DownRest).
	
% Make sure first character in a string is upper case
to_upper_case(AtomIn, StringOut) :-
	% make sure we have a string...
	atomics_to_string([AtomIn], StringIn),
	% now convert first character to capital case
	string_chars(StringIn, [First | Rest]),
	upcase_atom(First, UpperCase),
	string_chars(StringOut, [UpperCase | Rest]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 	Helper predicate for applying a template (inserting Content into the Template)	%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
applyTemplate(Template, Content, Result) :-
	atomic(Content), format(atom(Result), Template, [Content]).
applyTemplate(Template, ParameterList, Result) :-
	is_list(ParameterList), format(atom(Result), Template, ParameterList).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 	Helper predicate for converting Prolog objects into strings for logging		%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
/**
 * log_info(+TypeString, +Term, -InfoString)
 *
 * Prefix TypeString to the Term turned into an atom to return an Info string that can be
 * fed into the log action of MARBEL.
 *
 * @TypeString: A string.
 * @Term: Any Prolog term.
 * @InfoString: String where TypeString has been prefixed to Term.
**/
log_info(TypeString, Term, InfoString) :-
	term_to_atom(Term, Atom), string_concat(TypeString, Atom, InfoString).



% ---------------------------------------------------------
% JSON Formatters for Visuals
% ---------------------------------------------------------

% Convert filter history list to JSON for progress tracker
% Input: [12, 45, 150, 800] (most recent first)
% Output: '{"history":[800,150,45,12],"current":12,"start":800,"percentage":98}'
filter_history_to_json([], '{"history":[],"current":0,"start":0,"percentage":0}').
filter_history_to_json(History, JSONString) :-
    History \= [],
    reverse(History, Chronological),  % Convert to chronological order [800, 150, 45, 12]
    Chronological = [Start|_],
    History = [Current|_],
    % Calculate percentage of recipes filtered out
    (Start > 0 -> Percentage is round(((Start - Current) / Start) * 100) ; Percentage = 0),
    % Build the history array string
    atomic_list_concat_numbers(Chronological, ',', HistoryStr),
    % Construct JSON
    atomic_list_concat([
        '{"history":[', HistoryStr, '],',
        '"current":', Current, ',',
        '"start":', Start, ',',
        '"percentage":', Percentage, '}'
    ], JSONString).

% Helper to concatenate a list of numbers into a comma-separated string
atomic_list_concat_numbers([], _, '').
atomic_list_concat_numbers([X], _, Str) :- atom_number(Str, X).
atomic_list_concat_numbers([X,Y|Rest], Sep, Str) :-
    atom_number(XStr, X),
    atomic_list_concat_numbers([Y|Rest], Sep, RestStr),
    atomic_list_concat([XStr, Sep, RestStr], Str).

% Convert a list of Recipe IDs into a JSON string for the Grid View (Overview 2)
% Output format: '[{"name":"Pizza", "image":"url"}, ...]'
recipes_to_json([], "[]").
recipes_to_json(RecipeIDs, JSONString) :-
    findall(JsonObj, (
        member(ID, RecipeIDs),
        recipeName(ID, NameAtom),
        picture(ID, URLAtom),
        
        % Convert atoms to strings to avoid quote issues
        atom_string(NameAtom, Name),
        atom_string(URLAtom, URL),
        
        % Construct one JSON object string
        % Note: We use single quotes for Prolog atoms, double quotes for JSON content
        atomic_list_concat(['{"name":"', Name, '", "image":"', URL, '"}'], JsonObj)
    ), JsonList),
    
    % Join all objects with commas
    atomic_list_concat(JsonList, ',', InnerContent),
    % Wrap in brackets
    atomic_list_concat(['[', InnerContent, ']'], JSONString).

% Convert a single Recipe ID to a JSON string for Confirmation View
% Used for: The Confirmation Page
% Output: '{"name":"Pizza", "image":"url", "time":45, ...}'
recipe_to_json(ID, JSONString) :-
    recipeName(ID, NameAtom),
    picture(ID, URLAtom),
    time(ID, Time),
    servings(ID, Servings),
    cuisine(ID, CuisineAtom),

    (findall(IQ, ingredientAndQuantity(ID, IQ), IQs), IQs \= [] -> IngredientsList = IQs ; findall(I, ingredient(ID, I), IngredientsList)),
    findall(StepText, step(ID, _, StepText), StepsList),

    atom_string(NameAtom, Name),
    atom_string(URLAtom, URL),
    atom_string(CuisineAtom, Cuisine),

    % Convert Prolog lists to JSON arrays of strings
    list_to_json_array(IngredientsList, IngredientsJSON),
    list_to_json_array(StepsList, InstructionsJSON),

    atomic_list_concat([
        '{"name":"', Name, '", ',
        '"image":"', URL, '", ',
        '"time":', Time, ', ',
        '"servings":', Servings, ', ',
        '"cuisine":"', Cuisine, '", ',
        '"ingredients":', IngredientsJSON, ', ',
        '"instructions":', InstructionsJSON, '}'
    ], JSONString).

% to convert to json
list_to_json_array([], "[]").
list_to_json_array(List, JSON) :-
    findall(EscapedQuoted, (
        member(Item, List), convert_to_string(Item, S), escape_double_quotes(S, Esc), atomic_list_concat(['"', Esc, '"'], '', EscapedQuoted)
    ), QuotedList),
    atomic_list_concat(QuotedList, ',', Inner),
    atomic_list_concat(['[', Inner, ']'], JSON).

escape_double_quotes(In, Out) :-
    split_string(In, '"', '"', Parts),
    atomic_list_concat(Parts, '\\"', Out).


% Accept only real time expressions
valid_duration(Dur) :-
    term_to_atom(Dur, A0),
    downcase_atom(A0, A),
    ( sub_atom(A, _, _, _, 'min')
    ; sub_atom(A, _, _, _, 'minute')
    ; sub_atom(A, _, _, _, 'hour')
    ; sub_atom(A, _, _, _, 'hr')
    ).
