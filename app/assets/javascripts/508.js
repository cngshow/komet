$(document).on('page:load ready', function(){
	//xml import
	$(document).on('keydown', '.submit.xml-import-button', function(e){
		var e = getEvent(e);
    var keyCode = getKeyCode(e);

		if (e.keyCode == 9 && !e.shiftKey) {
			e.preventDefault();
			console.log('running')
			$('[accept=".xml"]').focus();
		};
	});
	$(document).on('keydown', '[accept=".xml"]', function(e){
		var e = getEvent(e);
    var keyCode = getKeyCode(e);

		if (e.keyCode == 9 && e.shiftKey) {
			e.preventDefault();
			console.log('running')
			$('.submit.xml-import-button').focus();
		};
	});

});