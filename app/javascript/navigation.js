// Toggle Button for Navigation
document.addEventListener("turbo:load", function () {
  const toggleBtn = $("#toggleBtn");
  const navContainer = $("#collapseExample");

  toggleBtn.on("click", function () {
    setTimeout(function () {
      if (navContainer.hasClass("show")) {
        $(".toggle-btn")
          .removeClass("fa-solid fa-circle-down")
          .addClass("fa-solid fa-circle-up");
      } else {
        $(".toggle-btn")
          .removeClass("fa-solid fa-circle-up")
          .addClass("fa-solid fa-circle-down");
      }
    }, 545); // 545 milliseconds delay
  });

  // Warehouse Selection AJAX Request
  $("#warehouse_select_dropdown").on("change", function () {
    var warehouseSelect = $(this).val();
    $.ajax({
      type: "GET",
      url: "/updating_selectedwarehouse_by_dropdown",
      data: { new_warehouse: warehouseSelect },
      dataType: "json",
      success: function (response) {
        location.reload();
        console.log(response);
      },
      error: function (error) {
        console.error("AJAX request failed:", error);
      },
    });
  });

  // Logo Click Redirect
  $("#logo").on("click", function () {
    window.location.href = "/dashboard";
  });
});

document.addEventListener("turbo:load", () => {
  // Listen for any Bootstrap modal hidden event
  document.body.addEventListener("hidden.bs.modal", ({ target }) => {
    document.querySelectorAll(".modal-backdrop").forEach(el => el.remove());
    // Remove the modal content from the DOM
    if (target.id === "conbalModal") {
      const frame = document.getElementById("positive_release_modal");
      if (frame) frame.innerHTML = "";
    }
  });
});
