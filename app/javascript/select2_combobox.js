

var context;

document.addEventListener("turbo:load", () => {

  $('body').on('hidden.bs.modal', function() {
    modalId = this.id;
    if(modalId != "" && modalId.includes('chapter99WarningModal') != true) {
      $('#'+modalId).remove();
    }
  });

/*
  $('body').on('shown.bs.modal', function(){
    $(this).find('.modal-body').append("<input type='text' id='copiedText'></input><button class='clipboard-btn hide' data-clipboard-action='copy' data-clipboard-target='#copiedText' id='clipboard'> Copy to clipboard  </button>");
    $("#copiedText"). attr("readOnly", true);
    // $(this).find('.modal-body').prepend('<div class="custom-tooltip"><span class="tooltiptext">Copy<span></div>')
  })
*/
  var addHighlighterror = function () {
    $('.select2-hidden-accessible').each(function(i, elem){
      if($(elem).hasClass('highlighterror'))
      {
        id = $(elem).prop('id');
        $('[aria-labelledby*="' + id + '"]').addClass('highlighterror')
      }
    })
  }

});


function assignValuesToFields(id) {
  var url = getUrl(id);
  $('#'+id).change(function() {
    port_id = this.value;
    myFunc(id, port_id, url);
  })

}

var applySelect2 = function(modalId) {
  modalId = $('.modal').attr('id')
    $('.modal select').each(function(){
      var options;
      var url;

      if(!options) {

        if(url) {
          options = {
            theme: "bootstrap",
            dropdownParent: $('#'+modalId),
            allowClear: allowClear,
            placeholder: '',

            ajax: {
              url: url,
              dataType: 'json',
              delay: 100,
              data: function (params) {
                return {
                  q: params.term, // search term
                  page: params.page
                };
              },
              processResults: function (data, params) {
                params.page = params.page || 1;
                if (thisId == 'selectTab') {
                  data.results.push({id: 'ALL', text: 'ALL'});
                }
                return {
                  results: data.results,
                  pagination: {
                    more: (params.page * 20) < data.count_filtered
                  }
                };
              }
            }

          }
        } else {
          options = {
            theme: "bootstrap",
            dropdownParent: $('#'+modalId),
            allowClear: allowClear,
            placeholder: ''
          }
        }
      }
      $(this).select2(options).on('select2:open', function(evt) {
        context = $(evt.target);
        search_val = $(this).val();
      });
    })
      addHighlighterror();
  }







    $("ul.dropdown li").click(function() {
      $(this).toggleClass("active");
    });
    $(".dropdown-toggle").click(function() {
      $("ul.dropdown").toggleClass("fade");
    });




var addHighlighterror = function () {
  $('.select2-hidden-accessible').each(function(i, elem){
    if($(elem).hasClass('highlighterror'))
    {
      id = $(elem).prop('id');
      $('[aria-labelledby*="' + id + '"]').addClass('highlighterror')
    }
  })
}

$(document).on('change', '[name*="ftz_indicator"]', function(){
  applySelect2($('.modal').attr('id'))
})



$(document).bind('keydown.select2', function(e) {
  //console.log("keydown "+ e.ctrlKey);
  searchFieldAriaActiveDescendand = $('.select2-search__field:eq(0)').attr('aria-controls')
  opened_box_id = searchFieldAriaActiveDescendand.split('-')[1]
  opened_box_id = '#'+opened_box_id

  if ( (e.which == 67 && e.ctrlKey) || (e.ctrlKey && e.which == 88) ) {
    if(context) {
      var highlighted = context.data('select2').$dropdown.find('.select2-results__option--highlighted');
      if (highlighted) {
        txt = highlighted.text();
        if (search_val != txt) {
          if ($(opened_box_id).attr('class').split(' ').includes('assigned-select-box')){
            e.preventDefault();
            return false;
          }
          $('#copiedText').val(txt);

          $("#clipboard").trigger('click');
        } else {
          console.log('Not able to copy select option');
        }
      }
    }
  } else if(e.which == 86) {
    $('.select2-search__field').on('paste', function(){
      console.log("paste");
      if ($(opened_box_id).attr('class').split(' ').includes('assigned-select-box')){
        e.preventDefault();
        return false;
      }
    })

  }

});


$(document).on('select2:open', function(e) {
      select_box = $(e.target);
      search_part2 = select_box.val();
      if (search_part2) {
        $('.select2-search__field').val(search_part2);
        $('.select2-search__field').trigger('change.select2')
      }
});
