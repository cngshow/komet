Komet Changelog 

This changelog summarizes changes and fixes which are a part of each revision.  For more details on the fixes, refer tracking numbers 
where provided, and the git commit history.

* 2017/01/?? - 1.59 - PENDING
    * changed so errors in attached sememe processing don't kill the app.

* 2017/01/19 - 1.58
    * Updated to latest enunciate file
    * Changed mapset so that you can edit extended fields

* 2017/01/12 - 1.57
    * isaac contexts branch is merged in

* 2017/01/12 - 1.56
    * Added a warning message if attempting to leave a page that has unsaved changes. Does not show if reloading the entire page, only if navigating to another section.
    * Fixed issue with mapsets ordering the common extended fields inconsistently.
    * User pref screen changed to logging info.

* 2017/01/05 - 1.55
    * Fixed issue with search grid that caused the grid not to show results.
    * Cleaned up search export code, changed so search results are not run until the export button is clicked.
    * Added unmapped option to Mapping Qualifier as per defect 418372
    * Fixed refset grid so it can be navigated with the keyboard.
    * Added wait cursor to show when a mapping or concept viewer is being loaded, or when a search is performed.
    * Added debugging code to help figure out edit cancel bug (blank screen) on SQA

* 2016/12/28 - 1.54
    * Fixed concept clone from creating a duplicate FSN dialect
    * Changed code so on creation of a concept description if no dialect is added it will automatically add US English as a preferred dialect.
    * Fixed bug in concept create due to hardcoded language sequence ID that has since changed. This was stopping create from working. Switched to using ID from metadata
    * Fixed Hyphen misspelling on Add Map Items dialog
    * Added ability to tab into search and refset grids, and then navigate the grids with keyboard commands

* 2016/12/20 - 1.53
    * Fixed CSS issues with the Add Map Fields dialog boxes in IE.
    * Fixed the autosuggest recent calls so they cache properly
    * Added Refset sections under Concept and Descriptions on the concept edit screen.
    * Updated to latest enunciate file
    * Changed to latest taxonomy ID names in metadata.
    * Removed hardcoded 'CODE' UUID, getting it from metadata now
    * refactor code of user preference screen to fix unknown bug in unix environment defect # 421416
    * fixed defect # 369888 CSV export on search page was not exporting all the records
    * Checking that targetConcept exists on associations call during concept edit
    * Added functionality to the mapping STAMP control
    * Removed refresh button when looking at set details
    * Fixed typo in logging file that was causing errors

* 2016/12/16 - 1.52
    * Fixed issue with mapping effective date not parsing dates correctly
    * Fixed clone concept error with snomed concepts
    * Taxonomy IDs are removed from cloned concepts
    * Description VUIDs show in read-only mode on concepts
    * resolved issue with export csv file
    * added verification code to make sure taxonomy concepts are in metadata before running code on them

* 2016/12/07 - 1.51
    * Fixed edit concepts so the extended description type field is a dropdown with text choices
    * Edit concepts extended description type field dropdown works with new properties.
    * Added HTML escaping to edit concepts and mapping, so that HTML characters don't break the GUI or allow XSS attacks.
    * Fixed HTML characters in the trees
    * Fixed little bit of inconsistent behaviour of custom shape and color functionality.

* 2016/12/06 - 1.50
    * researched the code, and  changed the code of get coordinate token to accept only post. - this code changes will show the shape and color on all  servers
        defects 421416, 421398
    * Fixed map items so that items with blank numeric fields or dates do not get saved with '0' or bad dates.
    * Fixed Qualifier field on map item read only view so it does not show 'Undefined'.
    * Fixed Target Concept field on map item read only view so it shows the concept.
    * Fixed map items so you can omit the target concept field.
    * Autosuggest fields now display the proper preferred description from the matching concept. The actual matching text is also displayed if it isn't 
        identical to the preferred term.
    * Search now display the proper preferred description from the matching concept as well as the actual matching text.
    * Identifier search now gives a list of taxonomy types to search for IDs. If search type is ID or Description and a UUID is entered, it will search specifically 
        for UUIDs, otherwise it performs a sememe search. If you pick a specific ID type it performs a sememe search using that ID type as an assemblage to search in.

* 2016/12/04 - 1.49
    * Changed get_refset_list to use metadata variable instead of property file
    * Changed export date picker to include time as well
    * Changed so concept refset tab will not appear unless there are refsets to display
    * Updated to latest enunciate file (ID search)

* 2016/12/02 - 1.48
    * Map items save with map set. Only one save button.
    * Map items display as read only unless in edit mode
    * Dates in map items now display and save correctly
    * Check in for color shapes.  When a user logs out, his/her choices will not impact the next user that logs in.

* 2016/12/01 - 1.47
    * fixed 508 contrast error on mapset,concept detail and user perference page
    * Added state field to map items
    * Added a fix for selecting the start date as today for VHAT export


* 2016/11/30 - 1.46:
   * Fixed NAN text showing when adding new concept dialects
   * Fixed to allow all concepts to show in the associations target field
   * Mapping business rules are stored under the correct concept ID
   * New dialects will now be created
   * Fixed bug causing dialects to always be set to inactive
   * Added a fix for selecting the start date as today for VHAT export
   * Active/Inactive filter control now works to change the state filter in queries, and the control css updates correctly. However, inactive items are not showing in when the filter is set to 'inactive'. It looks to be a bug on the ISAAC REST side.

* 2016/11/29 - 1.45:
    * Edit Concept Screen various 508 fixes.  Contrast on assoc value labels (Mod css)  Labels, header and titles added to text not being read by JAWS.
    * Fixed 508 error and alert - Concept details - Attached Sememes	before status column - removed empty th from table
    * Fixed 508 error and alert - Concept details - Attached Sememes- dynamic columns	added word prefix with word title  - dynamic column header names
    * Fixed 508 error and alert - Above taxonomy -stated & inferred button 	added fieldset and legend to radio button
    * Fixed 508 error and alert - Concept detail - navigation on blue bar -stated & inferred button 	added fieldset and legend to radio button
    * Fixed 508 error and alert - Users preference screen -stated & inferred button 	added fieldset and legend to radio button
    * Fixed 508 error and alert - Mapping tab - mapping detail page - blue bar navigation	added fieldset and legend to radio button
    * Fixed 508 error and alert - Mapping detail page - fixed all the check box and radio button	added fieldset and legend to radio button
    * Fixed 508 error and alert - Concept edit page - fixed all the check box and radio button	added fieldset and legend to radio button
    * Fixed 508 error and alert - Mapping tab - blue bar above tree - blue bar navigation	added fieldset and legend to radio button
    * Fixed 508 error and alert - Mapping detail page- click on plus sign to add row in grid	added label to dropdown
    * Users preference screen removed console.log 

* 2016/11/28 - 1.44:
    * No changes

* 2016/11/28 - 1.43:
    * Fixed bug adding a property to a description when editing a concept
    * Fixed 508 errors in concept edit, user preferences, and map sets for missing labels and unlabeled form elements,
      unused hidden buttons (X) in dialog boxes.
    * Fixed 508 errors and alerts for Map Set details and items, User Preferences, and Export related to missing form labels,
      empty buttons, broken Aria references, unlabeled form elements, device dependent event handlers and redundant titles.
    * Updated to latest enunicate file.
    * Made changes to match latest REST API changes

* 2016/11/23 - 1.42:
    * No changes

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
