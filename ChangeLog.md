Komet Changelog 

This changelog summarizes changes and fixes which are a part of each revision.  For more details on the fixes, refer tracking numbers 
where provided, and the git commit history.

* 2016/11/? - ?:
    * 508 fix - Navigation with JAWS not reading the user id - reads labels but preference is for Jaws to actually read the actual user id,
      for now fix is just stating user id region.  Also a few other title tags missing on nav region that were not being read with JAWS.

* 2016/11/28 - 1.43:
    * Fixed bug adding a property to a description when editing a concept
    * Fixed 508 errors in concept edit, user preferences, and map sets for missing labels and unlabeled form elements,
      unused hidden buttons (X) in dialog boxes.

* 2016/11/23 - 1.43:
    * Fixed 508 errors and alerts for Map Set details and items, User Preferences, and Export related to missing form labels,
      empty buttons, broken Aria references, unlabeled form elements, device dependent event handlers and redundant titles.
    * Updated to latest enunicate file.
    * Made changes to match latest REST API changes

* 2016/11/22 - 1.41:
    * Added clone concept functionality. Some parts are still not working correctly; any properties on the original FSN description are not copied over, 
      and adding new dialects to an existing description does not work.
    * Fixed business rules on mapsets. Note that this is only available on creating a new mapset, you can not edit the rules once the mapset is created.
    * fixed bugs on User pref screen -  correct color and shape will show on taxonomy .
    * added time picker to date pickers

* 2016/11/18 - 1.40:
    * Added STAMP time to preferences page
    * fix a bug on mapping roles
    * fix a bug with the edit concept button

* 2016/11/18 - 1.39:
    * Fixed refset grid not reloading when new inline concept is shown and refset section is already expanded
    * Fixed refset grid to actually show data

* 2016/11/18 - 1.38:
    * Fixed a bug where logging into komet A would break an existing Komet B session
    * Adding better session timeout management (provide a notice of an upcoming timeout)
    * Added shapes to the refsets prefs screen
    * Fixed window cancel bug
    * Fixed 418367 - missing vuid on mapset
    * Fixed 418373 Added UUID to mapset display
    * Fixed comment issues on mapsets
    * Fixed a bug with mapping and roles
    
* 2016/11/10 - 1.37:
    * Hide refset and inbox tabs
    * Added mergeConcept flag to autosuggest searches
    * Added restrict flag to autosuggest searches
    * Fixed map item cell height
    * Fix more SSO issues
    * Refix 508 issue to add href="#' back to navigation so that user 'tab' keying through nav works again
    * Fix a role cache timeout issue

* 2016/11/09 - 1.36:
    * added comments to map sets and items.

* 2016/11/08 - 1.35:
    * Added an "All Description Types" option to the search panel.

* 2016/11/08 - 1.34: 
    * 508 code fixed - added code for missing label and removed empty link and added code to show default cursor. Added aria-labelledby as needed
    * Updates to cache clearing code for clearing after a call to a /write method
    * Updates to the VHAT export code to try to get through the reverse proxy
    * Added mapping qualifier as standard map item field.
    * Fixed problem with javascript calls taking too much time with lots of auto suggest fields on the page
    * 508 bug fixes for defects # 394189, 394202, 394199, 394216
    * fixed 508 errors - empty buttons-  added label-aria and Broken ARIA reference on dropdown and radio button. Tool generate error
    * Slight 508 fix to workflow toolbar contrast critical error on wave tool, font to light where version being displayed


* 2016/11/03 - 1.33: 
    * See the GIT changelog for updates prior to this release.
