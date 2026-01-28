/** 
 * Javascript code for the Project Conversational Agents course.
 * 
 * This code makes some basic assumptions about the interaction protocol:
 * - User always is the first to say something (by turning on the microphone)
 * - The microphone automatically is closed again when a transcript has been received (the user has said something)
 * - After receiving a transcript, the turn is given to the agent and the user cannot turn on the microphone.
 * - When the agent has said something, the turn is handed back to the user.
 * 
 * This code also makes assumptions about the names of two buttons: the 'start' and 'mic'(rophone) button.
 * Button clicks are passed on to the webserver, which passes them on to the MARBEL agent using an EIS connector.
 * 
 * Finally, on pages where there is a microphone, a footer should be present with a <p> element with id="transcript".
 * This element will be used to display the transcript received from the ASR component.
 * 
 * SocketIO is used to communicate with the server.
*/

"use strict";

// Establish a WebSocket connection with the Flask server
var socket = io();

// Flag to keep track of whose turn it is (true --> user, false --> agent)
// Initially, it is the agent's turn; DO NOT CHANGE here, this flag is set by EISComponent in SIC framework
var user_turn = false;

// Persist turn across page navigations (otherwise it resets to false after redirects)
try {
  const storedTurn = sessionStorage.getItem("user_turn");
  if (storedTurn !== null) user_turn = (storedTurn === "true");
} catch (e) {}


// Variable to keep track of number of recipes that fullfill criteria
var recipecounter = -1;

// Code for handling button elements on page
var elements = document.getElementsByClassName("btn");

// Send button clicks to server
var sendButtonClick = function() {
    var name = this.getAttribute("id");
    socket.emit('buttonClick', name); // send button name to web server
};

for (var i = 0; i < elements.length; i++) {
    elements[i].addEventListener('click', sendButtonClick, false);
}

// Dedicated event listeners for two SPECIAL BUTTONS: the 'mic' button.
// Event listener for the mic button to toggle from off to on
// - We need to check if button is available on the webpage, as this may not be the case, e.g. not on start webpage.
// - The socket handler for 'transcript' event turns it off again, see below.
var micButton = document.getElementById('mic');

/* if (micButton) {
    micButton.addEventListener('click', function() {
        if (user_turn) {
            document.getElementById('micimg').src  = 'static/images/mic_on.png';
        } else {
            alert("It is not your turn.")
        }
    });
} */

if (micButton) {
  micButton.addEventListener('click', function (e) {
    if (user_turn) {
      const micimg = document.getElementById('micimg');
      if (micimg) micimg.src = 'static/images/mic_on.png';
    } else {
      alert("It is not your turn.");
      e.preventDefault();
      e.stopImmediatePropagation(); // prevents the generic .btn handler from firing too
    }
  });
}


// Event handler for successful connection
socket.on('connect', function() {
    console.log('Connected to the server.');
});

// Event handler for connection errors
socket.on('connect_error', function(error) {
    console.log('Connection error:', error);
});

// Event handler for disconnection
socket.on('disconnect', function() {
    console.log('Disconnected from the server.');
});

//Event handler for transcript event
// socket.on("transcript", (text) => {
//     document.getElementById("transcript").innerHTML = text;
// });

socket.on("transcript", (text) => {
  const el = document.getElementById("transcript");
  if (el) el.innerHTML = text;
});



// trying recipe confirmation fix
/* socket.on("pattern", (pattern) => {
    switch(pattern) {
        case "a50recipeSelect":
            if (recipecounter > 15) {
                window.location.href = "recipe_overview.html";
            } else {
                window.location.href = "recipe_overview2.html";
            }
            break;
        case "start":
            window.location.href = "start.html";
            break;
        case "c10":
            window.location.href = "welcome.html";
            break;
        default:
            window.location.href = "closing.html";
    }
}); */
socket.on("pattern", (pattern) => {
  console.log("[pattern]", pattern);

  // Fallback navigation ONLY for early pages, because your backend
  // apparently doesn't send a 'page' event for them yet.
  if (pattern === "start") {
    window.location.href = "start.html";
  } else if (pattern === "c10") {
    window.location.href = "welcome.html";
  }

  // Important: no default redirect to closing!
});



// Allow explicit page navigation from the agent
socket.on("page", (pageName) => {
    // Only redirect if we aren't already on that page to prevent loops
    console.log("[page]", pageName);
    if (window.location.pathname.indexOf(pageName) === -1) {
        window.location.href = pageName;
    }
});

// Event handler for switching turns
/* socket.on("set_turn", (whoseturn) => {
    if (whoseturn=="true") {
        user_turn = true;
    } else {
        user_turn = false;
    }
    // If it's not the user's turn (any more), then make sure the microphone icon is mic_out
    if (!user_turn) {
        document.getElementById('micimg').src  = 'static/images/mic_out.png';
    }
}) */

socket.on("set_turn", (whoseturn) => {
  user_turn = (whoseturn === "true");

  // persist across page redirects
  try { sessionStorage.setItem("user_turn", user_turn ? "true" : "false"); } catch (e) {}

  // update mic icon if it exists on this page
  const micimg = document.getElementById('micimg');
  if (!user_turn && micimg) {
    micimg.src = 'static/images/mic_out.png';
  }
});


// socket.on("recipecounter", (number) => {
//     recipecounter = number;
//     document.getElementById("recipecounter").innerHTML = recipecounter;
// })

socket.on("recipecounter", (number) => {
  recipecounter = number;
  const el = document.getElementById("recipecounter");
  if (el) el.innerHTML = recipecounter;
});


// Progress tracker handler - shows filtering journey
socket.on("progress", (dataString) => {
    console.log("Progress update:", dataString);
    try {
        var data = JSON.parse(dataString);
        
        // Update progress bar
        var progressBar = document.getElementById("progressBar");
        var progressPercent = document.getElementById("progressPercent");
        var progressStart = document.getElementById("progressStart");
        var progressSteps = document.getElementById("progressSteps");
        
        if (progressBar) {
            progressBar.style.width = data.percentage + "%";
            progressBar.setAttribute("aria-valuenow", data.percentage);
        }
        if (progressPercent) {
            progressPercent.innerHTML = data.percentage;
        }
        if (progressStart) {
            progressStart.innerHTML = data.start;
        }
        
        // Build step indicators showing the filtering journey
        if (progressSteps && data.history && data.history.length > 0) {
            var stepsHtml = "";
            data.history.forEach((count, index) => {
                var isLast = (index === data.history.length - 1);
                var badgeClass = isLast ? "badge bg-success" : "badge bg-secondary";
                stepsHtml += '<span class="' + badgeClass + ' mx-1">' + count + '</span>';
                if (!isLast) {
                    stepsHtml += '<span class="text-muted">→</span>';
                }
            });
            progressSteps.innerHTML = stepsHtml;
        }
    } catch (e) {
        console.log("Error parsing progress data:", e);
    }
});

// Example showing how to work with templates
// Adding filters to a card deck on an HTML page
socket.on("filters", (filterString) => {
    const filtersString = filterString.substring(1, filterString.length-1);
    if (filterString.length != 0) {
        const filters = filtersString.split(',');
        document.getElementById("addFiltersHere").innerHTML = "";
        filters.forEach((element) => {
            filterCard(element);
        });
    }
})

// DONE: TODO: Show recipe cards on HTML page

// Handle the grid of recipes (for recipe_overview2.html)
socket.on("show_recipes", (data) => {
    // data comes in as a JSON string from Prolog/Python
    console.log("Received recipes:", data);
    var recipes = JSON.parse(data); 
    
    var container = document.getElementById("recipeContainer"); // Matches HTML ID
    var template = document.querySelector("#recipeCardTemplate");
    
    // Only run if we are on the correct page
    if (container && template) {
        container.innerHTML = ""; // Clear existing

        recipes.forEach((recipe) => {
            var clone = template.content.cloneNode(true);
            
            // Set Title
            clone.querySelector(".recipe-title").textContent = recipe.name;
            
            // Set Image
            var img = clone.querySelector(".recipe-img");
            if (img) img.src = recipe.image;
            
            container.appendChild(clone);
        });
    }
});

// DONE: TODO: After selection has been made, show a specific recipe in a card with its details

// Handle single recipe confirmation (for recipe_confirmation.html)
socket.on("show_confirmation", (data) => {
    console.log("Confirming:", data);
    var recipe = JSON.parse(data);

    // Update the DOM elements if they exist
    var title = document.getElementById("confirmTitle");
    var img = document.getElementById("confirmImg");
    var time = document.getElementById("confirmTime");
    var serv = document.getElementById("confirmServings");
    var cuis = document.getElementById("confirmCuisine");
    var ingredientsList = document.getElementById("confirmIngredients");
    var instructionsList = document.getElementById("confirmInstructions");

    if (title) title.textContent = recipe.name;
    if (img) img.src = recipe.image;
    if (time) time.textContent = recipe.time;
    if (serv) serv.textContent = recipe.servings;
    if (cuis) cuis.textContent = recipe.cuisine;

    if (ingredientsList && Array.isArray(recipe.ingredients)) {
        ingredientsList.innerHTML = "";
        recipe.ingredients.forEach((ing) => {
            let li = document.createElement("li");
            li.className = "list-group-item";
            li.textContent = ing;
            ingredientsList.appendChild(li);
        });
    }

    if (instructionsList && Array.isArray(recipe.instructions)) {
        instructionsList.innerHTML = "";
        recipe.instructions.forEach((step) => {
            let li = document.createElement("li");
            li.textContent = step;
            instructionsList.appendChild(li);
        });
    }
});


// TODO: Utility function to parse string representations of arrays (e.g., "[chorizo, cheese]")


// Create and add a single card for a filter based on the template in the HTML file
// See also https://www.w3schools.com/tags/tag_template.asp
function filterCard(filter) {
    let filterTemplate = document.querySelector('#filterCardTemplate');
    const card = filterTemplate.content.cloneNode(true);
    card.querySelector('#filterText').innerHTML = filter;
    document.getElementById("addFiltersHere").appendChild(card);
}