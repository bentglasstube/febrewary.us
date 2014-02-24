$(function() {
  $('.slider').slider().on('slide', function(e) {
    var id = $(this).attr('id');
    // Some kind of garbage way to get the value
    var value = $(this).slider().data('slider').getValue();
    console.log('slideStop for ' + id + ': ' + value);
    $('#' + id + '-value').attr('value', value);
  });
});
