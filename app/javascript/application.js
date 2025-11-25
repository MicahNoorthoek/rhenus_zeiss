import "@hotwired/turbo-rails";
import "controllers";
import $ from "jquery";
window.$ = window.jQuery = $; // Make jQuery available globally
import "select2";
import "bootstrap"; // Ensure Bootstrap is imported
import "navigation";
//import "./dashboard";
import "custom_filter";
//import "./select2_combobox";
//import "./select2";

function initFlashMessage() {
  //$(".select2").select2();
//console.log("initFlashMessage called");
  const $flash = $('#error-container')
    console.log($flash)
    if ($flash.length) {
      let timerId
      const hide = () => $flash.css('right', '-100%')
      const show = () => {
        $flash.css('right', '0')
        timerId = setTimeout(hide, 5000)
       // barID = setTimeout(hide, 5000)
        
       $flash.find('.flash-progress-bar').css({ width: '100%' }).animate({ width: '0%' }, 5000, 'linear');

      }
  
      show()
      $flash
        .on('mouseenter', () => clearTimeout(timerId))

        .on('mouseleave', () => {
          clearTimeout(timerId)
          timerId = setTimeout(hide, 1000)
        //  barID = setTimeouet(hide, 1000)
        })
    }
}

document.addEventListener("turbo:load", initFlashMessage);
document.addEventListener("turbo:frame-load", initFlashMessage);

// Initialize Select2 after Turbo loads
//document.addEventListener("turbo:frame-load", () => {
//  $(".select2").select2();
    //Flash‐message show/hide logic
    

//});


  // Apply Select2 to modal 
window.applySelect2 = function(modalId) {
    const $modal = $(`#${modalId}`);
  
    $modal.find('select').each(function () {
      $(this).select2({
        placeholder: `Select ${$(this).attr('id')?.split('-')[0]?.toUpperCase()}...`,
        allowClear: true,
        dropdownParent: $modal
      });
    });
  };
  

  // clearing SPC/Client PO
window.restrictSpcAndClientpoSubmission = function (x) {
    if (x === 'clientpo') {
      if ($("#clientpo-input").val() !== '') {
        $("#spc-select-dropdown").val("Select SPC...");
      }
    } else {
      if ($("#spc-select-dropdown").val() !== 'Select SPC...') {
        $("#clientpo-input").val('Select Client PO...');
      }
    }
  };

  // Show modal when the Turbo Frame loads
  document.addEventListener("turbo:frame-load", function (event) {
    if (event.target.id === "select_criteria_modal") {
      const modal = document.querySelector("#myModal");
      if (modal) {
        const bootstrapModal = new bootstrap.Modal(modal);
        bootstrapModal.show();
  
        const modalId = modal.getAttribute("id");
        applySelect2(modalId);
  
        sessionStorage.removeItem("selectedReceipts");
        sessionStorage.removeItem("selectedReceiptsIds");
  
        $("#clientpo-input").on("click keyup", function () {
          restrictSpcAndClientpoSubmission('clientpo');
        });
  
        $("#spc-select-dropdown").on("click keyup", function () {
          restrictSpcAndClientpoSubmission('spc');
        });
      }
    }
  });

  // Show the edit user modal whenever the turbo frame updates
  document.addEventListener("turbo:frame-load", function (event) {
    if (event.target.id === "edit_user_modal") {
      const modal = document.querySelector("#editUserModal");
      if (modal) {
        const bootstrapModal = new bootstrap.Modal(modal);
        bootstrapModal.show();
      }
    }
  });



  document.addEventListener("turbo:load", function () {

    // Save tab selection in localStorage when tab is shown
    $('#myFeedTab a[data-toggle="tab"], #myFeedTab a[data-bs-toggle="tab"]').on('show.bs.tab', function(e) {
      localStorage.setItem('fedActiveTab', $(e.target).attr('href'));
    });

    var fedActiveTab = localStorage.getItem('fedActiveTab');
    if (fedActiveTab) {
      if (
        !window.location.href.includes("outsidereceipt") &&
        !window.location.href.includes("outsideshipment") &&
        !window.location.href.includes("outsideproduction")
      ) {
        // Try jQuery Bootstrap tab first
        if (typeof $().tab === 'function') {
          $('#myFeedTab a[href="' + fedActiveTab + '"]').tab('show');
        } else {
          // Bootstrap 5 fallback (native JavaScript)
          var el = document.querySelector('#myFeedTab a[href="' + fedActiveTab + '"]');
          if (el) {
            var tab = new bootstrap.Tab(el);
            tab.show();
          }
        }
      }
    } else {
      //$('#myFeedTab a:first').tab('show');
      var firstTab = document.querySelector('#myFeedTab a');
      if (firstTab) {
        var tab = new bootstrap.Tab(firstTab);
        tab.show();
      }
    }

    // Secondary tab handling
    $('#myTab2 a[data-toggle="tab"], #myTab2 a[data-bs-toggle="tab"]').on('show.bs.tab', function(e) {
      localStorage.setItem('secActiveTab', $(e.target).attr('href'));
    });

    var secActiveTab = localStorage.getItem('secActiveTab');
    if (secActiveTab) {
      // jQuery version
      if (typeof $().tab === 'function') {
        $('#myTab2 a[href="' + secActiveTab + '"]').tab('show');
        $('#myTab3 a[href="' + secActiveTab + '"]').tab('show');
      } else {
        // Bootstrap 5 fallback
        ['#myTab2', '#myTab3'].forEach(function(tabSelector) {
          var el = document.querySelector(tabSelector + ' a[href="' + secActiveTab + '"]');
          if (el) {
            var tab = new bootstrap.Tab(el);
            tab.show();
          }
        });
      }
    } else {
      var firstTab = document.querySelector('#myTab2 a');
      if (firstTab) {
        var tab = new bootstrap.Tab(firstTab);
        tab.show();
      }
    }
  });
