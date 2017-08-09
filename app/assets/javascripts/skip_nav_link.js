$(document).on('ready	 page:load', function(){
	$('a#skip-nav-link').on('keydown', function(e){
		  var e = getEvent(e);
      var keyCode = getKeyCode(e);
      if (keyCode == 13) {
      	e.preventDefault();
      	$('#maincontent button, #maincontent a').first().focus();
      };
	});
});


