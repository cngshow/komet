$(document).on('ready page:load', function(){
	//changing tabbing color to red when inside of panel heading
	var body = $('body');
	$(document).on('focusin', '.panel-heading, .komet-panel-tools-control, #komet_taxonomy_allowed_states', function(){
		setTimeout(function(){
			body.addClass("red-focus");
		});
	})
	$(document).on('focusout', '.panel-heading, .komet-panel-tools-control', function(){
			body.removeClass('red-focus');	
	});

	//Button Edit Concept focuses on first input when opened
	$(document).on('click', 'button[title="Edit Concept"]', function(){
		setTimeout(function(){
			body.removeClass('red-focus');	
			$('.komet-editor-form .panel-body').find('select, input').first().focus();
		}, 1000);
	});
});