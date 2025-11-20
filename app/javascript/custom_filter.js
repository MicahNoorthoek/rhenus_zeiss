document.addEventListener("turbo:load", function () {
  
$(document).on('click', ".custom-filter-plus-icon", function(){
  $('.custom-filter-main-div').toggleClass('hide');
  if ($('.custom-filter-main-div').hasClass('hide')){
    $('.custom-filter-sub-div').addClass('hide')
  }

});

$(document).on('click', ".filter-columns-p", function(){
  if (!$('.custom-filter-sub-div').hasClass('hide')){
    $('.custom-filter-sub-div').addClass('hide')
  }
  setTimeout(function() {
    $('.custom-filter-sub-div').toggleClass('hide');
  }, 100)
});


function ajaxForCustomForm(dom) {
  if (prevDom != null) {
    prevDom.removeAttr('style');
  }
  prevDom = dom;

  const filed_name = dom.attr('field_name');
  const field_type = dom.attr('field_type');
  const filter = dom.closest('.custom-filters');
  const scope = filter.data('scope');
  const searchFormId = filter.data('searchFormId');
  const fieldsId = filter.data('customSearchFormFields');
  const filterFormId = filter.data('filterFormId');

  dom.css({
    'border-radius': '4px',
    'background-color': 'rgb(199, 215, 133)',
    'width': 'fit-content'
  });

  $.ajax({
    url: '/create_filter_form',
    dataType: 'script',
    method: 'post',
    headers: {
    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
    'Content-Type': 'application/json'
  },
    data: JSON.stringify({
      filed_name: filed_name,
      field_type: field_type,
      scope: scope,

      search_form_id: searchFormId,
      fields_id: fieldsId,
      filter_form_id: filterFormId
    })
  })
}

var prevDom = null;

$(document).on('click', '.filter-columns-p', function() {
  ajaxForCustomForm($(this));
});

$(document).on('click', '.remove-filter-icon', function() {
  filter_id = $(this).closest('div').attr('id')
  filter = $(this).closest('.table-responsive').closest('.dashtable')
  if (filter.length == 0) {
    filter = $(this).closest('.table-responsive').closest('.filter-page')
  }

  filter_field = filter.find('.custom-filter-fields').find('.filter-field').find('[name*='+filter_id+']')
  filter_field.remove();

  default_search_input = filter.find('.search-form-submit').parents('.input-group').find('input')
  default_search_field_name = default_search_input.attr('name')
  if (typeof(default_search_field_name) != 'undefined' && default_search_field_name != null){
    default_search_by = default_search_field_name.substring(default_search_field_name.indexOf('[')+1, default_search_field_name.lastIndexOf(']'))
    if (default_search_by == filter_id){
      default_search_input.val("")
    }
  }

  filter.find('.search-form-submit').trigger('click');

})

$(document).on('click', '.remove-filter-icon2', function() {
  filter_id = $(this).closest('div').attr('id')

  filter = $(this).closest('.link-ship-advance-filter').closest('.dashtable')
  filter_field = filter.find('.custom-filter-fields').find('.filter-field')
  clicked_filter = filter_field.find('[name*='+filter_id+']')
  clicked_filter_id = "linkingship_" + filter_id
  shipment_filter_input = filter.find('#shipment_filter_input').find('input').attr('id')

  if (clicked_filter_id == shipment_filter_input){
    filter.find('#shipment_filter_input').html('');
    filter.find('#shipment_filter_input').append('<input class="form-control input-sm hide" type="text" name="linkingship[release_document_proxy_cont]" id="linkingship_release_document_proxy_cont">')
    filter.find("#fiter_by_value").val("release_document_proxy_cont");
  }
  clicked_filter.parent().remove();

  filter.find('.search-form-submit').trigger('click');

})

$(document).on('click', '.clear-search-result', function() {
  filter = $(this).closest('.table-responsive').closest('.dashtable');
  if (filter.length == 0) {
    filter = $(this).closest('.table-responsive').closest('.filter-page');
  }
  filter.find('.cancel-button').click();
})

$(document).on('click', '#toggle_filter', function() {
  $('#custom-filter-div').toggleClass('hide')
})

$(document).on('click', '#toggle_filter2', function() {
   $('#custom-filter-div').toggleClass('hide');

/*  filter = $(this).closest('.dashtable')
  if (filter.length == 0) {
    filter = $(this).closest('.filter-page')
  }
  filter.find('#custom-filter-div').toggleClass('hide')
  */
})

$(document).on('keypress', '.filter-search-filed', function (e) {
  var ingnore_key_codes = [34, 39];
  if ($.inArray(e.which, ingnore_key_codes) >= 0) {
      e.preventDefault();
  }
});

$(document).on('click', '.btn-filter', function() {
  $('.filter-search-filed').val($('.filter-search-filed').val().replace(/['"]/g, ''));
})
});