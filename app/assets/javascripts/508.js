$(document).on('ready page:load', function(){
	//changing tabbing color to red when inside of panel heading
	var body = $('body');
	$(document).on('focusin', '.panel-heading, .komet-panel-tools-control, #komet_taxonomy_allowed_states', function(){
		setTimeout(function(){
			var currentFocus = $($(':focus')[0]);
			body.addClass("red-focus");
			if (currentFocus.attr('type') === "checkbox" && currentFocus.parent().attr('class') === "komet-panel-tools-control") {
				addStyleOnPanelHeadingCheckbox();
			};
		});
	})
	$(document).on('focusout', '.panel-heading, .komet-panel-tools-control', function(){
			body.removeClass('red-focus');	
			removeStyleOnPanelHeadingCheckBox();
	});

	//Button Edit Concept focuses on first input when opened
	$(document).on('click', 'button[title="Edit Concept"]', function(){
		setTimeout(function(){
			body.removeClass('red-focus');	
			$('.komet-editor-form .panel-body').find('select, input').first().focus();
		}, 2000);
	});

	$(document).on('click', '#komet_taxonomy_search_form button', function(){
		setTimeout(function(){
			var agBodyContainer = $('.ag-body-container');
			if (agBodyContainer.children().length) {
				agBodyContainer.children()[0].focus();
			};
		},1000);
	});

	function addStyleOnPanelHeadingCheckbox(){
		var checkbox = $('.komet-editor-form input[type="checkbox"]')[1];
		$(checkbox).css({
			'outline-color': 'red',
			'outline-style': 'solid',
			'outline-offset': 0
		});
	};
	function removeStyleOnPanelHeadingCheckBox(){
		var checkbox = $('.komet-editor-form input[type="checkbox"]')[1]
		$(checkbox).css({
			'outline-color': '',
			'outline-style': ''
		});
	};
});