
/*
console.log("Dashboard script loaded");
var logoutTimer;
document.addEventListener("turbo:load", () => {
    function startLogoutTimer() {
    logoutTimer = setTimeout(logout, 20 * 60 * 1000); // 20 minutes
  }

  function resetLogoutTimer() {
    clearTimeout(logoutTimer);
    startLogoutTimer();
  }

  function logout() {
    // Redirect the user to the logout page or execute a logout action
    window.location.href = '/session_timeout';
  }

  // Start the timer when the user logs in or interacts with the application

  // Reset the timer on user interaction (e.g., mousemove or keydown events)
 document.addEventListener("turbo:load", () => {
    if (window.location.pathname === "/" || window.location.pathname === "/login" || window.location.pathname === "createuser_38923489d8234k234") {
    } else {
      // Code to execute if the current URL is not the root URL
      startLogoutTimer()
      resetLogoutTimer()
    }
  });


  document.addEventListener('click', function() {
    if (window.location.pathname === "/" || window.location.pathname === "/login" || window.location.pathname === "createuser_38923489d8234k234") {
    } else {
      $.ajax({
        url: '/checkifloggedout',
        success: function(response) {
          console.log(response.status)
          if (response.status == "user logged out") {
            console.log("logging out...")
            $.ajax({
              url: '/on_close',
              success: function(response) {
                console.log("done")
              },
              error: function(error) {
                //console.log('Error retrieving record: ' + error[1]);
              }
            });
          }
        },
        error: function(error) {
          //console.log('Error retrieving record: ' + error[1]);
        }
      });
    }
  });


  // Reset the timer on user interaction (e.g., mousemove or keydown events)
  document.addEventListener('mousemove', function() {
    if (window.location.pathname === "/" || window.location.pathname === "/login" || window.location.pathname === "createuser_38923489d8234k234") {
    } else {
      // Code to execute if the current URL is not the root URL
      resetLogoutTimer()
    }
  });

  document.addEventListener('keydown', function() {
    if (window.location.pathname === "/" || window.location.pathname === "/login" || window.location.pathname === "createuser_38923489d8234k234") {
    } else {
      // Code to execute if the current URL is not the root URL
      resetLogoutTimer()
    }
  });

  //  if ($("input[type=checkbox]:checked").length == 0) {
  //    alert("Please check at least one checkbox");
  //
  //  }
*/

document.addEventListener("turbo:load", () => {

    $(document).on('click', '#all_pick_doc', function(){
      if ($("input[type=checkbox]:checked").length == 0) {
        alert("Please check checkboxes");
        return false;
      } else {
        $.ajax({
          type: 'get',
          url: '/refresh_fedscraps',
          dataType: 'script'
        })
      }
    })


    // set hash on click without jump
    $(document.body).on("click", "a[data-toggle]", function(e) {
    //  $("#errorsTab").on("click", "a[data-toggle]", function(e) {
      e.preventDefault();
      if(history.pushState) {
        history.pushState(null, null, this.getAttribute("href"));
      }
      else {
        location.hash = this.getAttribute("href");
      }
      $('a[href="#' + location.hash.replace("#", "") + '"]').tab('show');

      // tabs = ['#rec', '#ersum', '#convey', '#parts']

      // if(tabs.includes($(e.target).attr('href')))
      // {
      //   path = window.location.href
      //   location.replace(path.split('?')[0] + '?page=1' + $(e.target).attr('href'));
      // }

      return false;
    });


    document.addEventListener("turbo:load", () => {
      console.log("tabs");
      $('#myFeedTab a[data-toggle="tab"]').on('show.bs.tab', function(e) {
        localStorage.setItem('fedActiveTab', $(e.target).attr('href'));
      });
      var fedActiveTab = localStorage.getItem('fedActiveTab');
      if(fedActiveTab){
        if (window.location.href.includes("outsidereceipt") || window.location.href.includes("outsideshipment") || window.location.href.includes("outsideproduction")) {
        } else {
        $('#myFeedTab a[href="#' + fedActiveTab.replace("#", "") + '"]').tab('show');
        // $('#myFeedTab a[href="' + fedActiveTab + '"]').tab('show');
        }
      } else {
        $('#myFeedTab a:first').tab('show');
      }
      //applySortable();
    });

    // on refresh go to current tab and page
    $('#myTab2 a[data-toggle="tab"]').on('show.bs.tab', function(e) {
      localStorage.setItem('secActiveTab', $(e.target).attr('href'));
    });
    var secActiveTab = localStorage.getItem('secActiveTab');
    if(secActiveTab){
      $('#myTab2 a[href="#' + secActiveTab.replace("#", "") + '"]').tab('show');
      $('#myTab3 a[href="#' + secActiveTab.replace("#", "") + '"]').tab('show');
    } else {
      $('#myTab2 a:first').tab('show');
    }


  $(document).on('click', '.warning-message-filter', function(){
    war_m = $('#errorestward_warning_message_in')
    if(war_m.length > 0) {
      war_m.val(' ');
      arrayDesc = [];
      $(this).closest('.eat_war_message').find('li.active .dropdown-text').each(function(i, elem){
        desc = $(elem).html().trim();
        arrayDesc.push(desc);
      })

      war_m.val(arrayDesc);
      war_m.closest('form').submit()
    }
  });


  $(document).on('click', '#all_pick_doc2', function(){
    if ($("input[type=checkbox]:checked").length == 0) {
      alert("Please check checkboxes");
      return false;
    }
  })


  preparedPaginationUrl = function(dom) {
    if (dom.prop('checked')){
      var selected_checkboxes = []
      var selectedCheckboxElement = dom.closest('.dashtable').find("input[type=checkbox]:checked")
      if(selectedCheckboxElement){
        selectedCheckboxElement.each(function(index, elem) {
          if (!selected_checkboxes.includes(elem.value)){
            selected_checkboxes.push(elem.value)
          }
        })
      }

      dom.closest('.dashtable').find('.pagination a').each(function(index, elem) {
        url = $(elem).attr('href')
        joinedSelectedCheckbox = selected_checkboxes.join('&selected_checkboxes%5B%5D=')
        splitedUrl = url.split('&')
        if(splitedUrl[1]){
          url = splitedUrl[0]
        }
        $(elem).attr('href', url + '&selected_checkboxes%5B%5D=' + joinedSelectedCheckbox)
      })
    }
  }

  // var selected_checkboxes2 = []
  $(document).on('change', '.checkbox-checkshipput', function() {
    preparedPaginationUrl($(this))
  });

  $(document).on('change', '.checkbox-checkpend', function() {
    preparedPaginationUrl($(this))
  });

  $(document).on('change', '.checkbox-checkshiprep', function() {
    preparedPaginationUrl($(this))
  });


/*
let logoutTimer;

function startLogoutTimer() {
  logoutTimer = setTimeout(logout, 20 * 60 * 1000); // 20 minutes
}

function resetLogoutTimer() {
  clearTimeout(logoutTimer);
  startLogoutTimer();
}

function logout() {
  // Redirect the user to the logout page or execute a logout action
  window.location.href = '/session_timeout';
}

// Start the timer when the user logs in or interacts with the application
document.addEventListener('DOMContentLoaded', startLogoutTimer);

// Reset the timer on user interaction (e.g., mousemove or keydown events)
document.addEventListener('mousemove', resetLogoutTimer);
document.addEventListener('keydown', resetLogoutTimer);
<% if session[:user_id].nil? %>

<% end %>
*/


/*
$(window).on('unload', function() {
    // Send an AJAX request to update the database
    $.ajax({
      type: 'GET',
      url: '/on_close',
      success: function(response) {
        console.log('Database updated successfully');
      },
      error: function(error) {
        console.error('Error updating database:', error);
      },
      async: true // This makes the request synchronous, you might want to use async: true in production
    });
  });
*/

})
