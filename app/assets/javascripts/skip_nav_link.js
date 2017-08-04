$(document).on('ready	 page:load', function(){
	$('a#skip-nav-link').on('keydown', function(e){
		  var e = getEvent(e);
      var keyCode = getKeyCode(e);
      if (keyCode == 13) {
      	e.preventDefault();
      	$('#maincontent button, #maincontent a').first().focus();
      };
	});

	function getEvent(e){
	    return (e || window.event);
	};
	function getKeyCode(e) {
	    return (e.keyCode ? e.keyCode : e.which);
	}; 

});


