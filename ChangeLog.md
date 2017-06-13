Komet Changelog 

This changelog summarizes changes and fixes which are a part of each revision.  For more details on the fixes, refer tracking numbers 
where provided, and the git commit history.

* 2017/06/?? - 4.8 - PENDING
    * Changes to Create, View, and Edit concept to support VHAT usage. Includes label changes, dynamic extended type description options in create and edit, hiding or showing description type,
       extended description type, and dialects depending on the terminology type, and other bug fixes. (Jazz: 529741)
    
* 2017/06/08 - 4.7
    * Added Generate VUID dialog (Jazz #501723)
    * Added module and VUID to autosuggest results
    * Added Export to Generate VUID dialog (Jazz #501723)

* 2017/05/25 - 4.6
    * Fixed issue were editing with more that one concept window open causes a javascript error and descriptions to not show. Removed unneeded bind() method from viewer objects. Optomized objects to only create prototype functions once.
    
* 2017/05/24 - 4.5
    * When adding a new property of extended description type to a concept it will appear with the dropdown options instead of a text field.
    * Fixed context menu on concept edit screen on concept and description properties that support it (mainly extended description type at the moment)

* 2017/05/21 - 4.4
    * Updated to latest enunicate
    * Incorporated changes to rest calls returning UUIDs in coordinates, taxonomy, concept APIs
    * Added VUID/CODE auto generation for vhat concepts (Jazz: 436924, 501726)
    * Fixed issue with search_term using extended description type field options (Jazz: 515733)
    * Fixed concept create issue
    * Extended types now work with their proper options for their terminology
    * Extended description types and some other forms of UUID properties will now show the concept description in the view window, with the UUID in a tooltip and 
        the concept sememe menu available
    * VUID generation via the rest service is working

* 2017/05/11 - 4.3
    * Fixed so multiple properties that have the same column name don't create duplicate columns

* 2017/05/05 - 4.2 
    * Added nested properties to the concept section in the concept viewer.
    * Added null role check in javascript security poll code to stop autosuggest error
    * Renamed State to Status in mapsets (Jazz: 440205)
    * Added STAMP fields to search options (Jazz: 485603)

* 2017/05/02 - 4.1
    * Fix a threading issue that prevented komet from deploying in certain circumstances.

* 2017/04/28 - 4.0.1
    * Rebuilding to catch updates in rails_common

* 2017/04/28 - 4.0
    * Fixed issue with processing the metadata version number since it doesn't have the same object format as the rest of the metadata
    * Changed global preference module query to pull all nested modules
    * Concept lineage section now shows number of children in both the linage and children tree headers (Jazz: 388563)
    * Added nested properties to descriptions in the concept viewer

* 2017/04/27 - 3.2
    * Build will break when the auxilliary metadat major version changes.  Komet dev will know to make the right changes.(Tied to the build process not for test)
    * Rewrote global preferences to make code reusable, easy to read and debug, and more user friendly. (Jazz: 452386)

* 2017/04/11 - 3.1
    * Allowed nested modules to be shown in the view parameters so all concepts can be displayed when choosing specific views (Jazz: 486439)
    * Updated to latest enunciate
    * changes to support latest metadata updates (module constants removed)
    * added support for new ID API method 'ids'
    * Changed preference window so preference queries are not run until the window is opened, instead of when the dashboard is loaded. (Jazz: 452386)
    * Updated to latest Enuniciate
    * Changes for edit tokens
    * Added view params to edit forms, passing view params to all API update calls. Changes to support this include modifying the trees to pass viewer information, pub/sub calls to support viewer info and
      view params, fixes for various places that were not correctly passing view params around.
    * JRuby upgrade branch from 9.0.4 to 9.1.8 (March 28th 2017)
      follow all instructions in prisme tied to the upgrade - especially related to installing a tool like http://www.issihosts.com/haveged/ to
      ensure that any linux boxes have proper entropy available.

* 2017/03/21 - 3.0.1
    * Rebuild of Release 3

* 2017/03/21 - 3.0
    * Fixed issue with nested rows not expanding in concept viewer attached sememes. Also fixed layout problems with nested rows in Chrome.
    * Fixed layout issues with mapping add fields dialog
    * Changed mapping add fields dialog positioning so it will cause a scrollbar to appear if the window shrinks. (Jazz: 482590)
    * Updated VHA_MODULES metadata name in the code, fixes tree loading issue. (Jazz: 484897)
    * Fixed so alerts will be read by AT on IE and when closed will focus on the next form element. (Jazz: 469380)
    * Reversioned from 1.69
    * Production build for Release 3

* 2017/03/16 - 1.68
    * Mapset include dialogs will now behave as expected if cancel is clicked, by returning to the state they were in prior to any changes. Fixed bug in that code that caused a previously added but cancelled field from being added again. (Jazz: 480730)
    * Added descriptive tooltips and aria-labels to mapset include dialog Change Order and Remove links.
    * Fixed issue with cancelling an edit when the previously displayed content was a Concept Viewer - was not correctly passing view params.
    * Fixed issue where duplicate fields could be added to a mapset or map items. (Jazz: 480738)

* 2017/03/15 - 1.67
    * Refactored a number of the view params and added Module as a param (Jazz: 461738)
    * Fixed Success messages to show in green banner, added success messages to concept create and edit, optimized some of the concept editing code
    * Added status preference to taxonomy and concept viewer (Jazz: 461738)
    * Changed status preference to only include Active and All (Jazz: 461738)
    * Fixed concept create and edit to properly transfer view params to the tree after editing a concept (Jazz: 461738)
    * Added path preference to view params for taxonomy, concepts, and mapping, though field is hidden currently  (Jazz: 461738)
    * Added descriptive error messages if the two required fields for a mapset are not filled in. (Jazz: 476665)

* 2017/03/08 - 1.66
    * Added role "alert" to error messages so they will be read by screen readers. They do not take the focus so that they don't interrupt the user flow, and because we add multiple at a time. Some messages can't contain detailed descriptions of the item affected if it is a new item. (Jazz: 469380)
    * Made concept viewer expand/collapse aria labels more descriptive of the sections they control. (Jazz: 469194)

* 2017/03/02 - 1.65
    * Added STAMP date to taxonomy tree, concept viewer, mapping tree, and mapping viewer. All related functions now take whatever per panel view params are passed from the GUI. Many css, renaming, code cleanup, and other refactors as part of this.
    * Added labels to "Add more map item fields" dialog
    * Made sure dialogs in map editor get the focus when they are displayed (Jazz: 469408)
    * Context and Mapping trees expand and collapse are accessible using left and right arrow keys and space bar. Context menu on tree is accessible using accent (`), Context Menu, and "Shift + F10" keys. Made sure tree does not retain respond to key commands when menu is open, and regains focus when menu is closed. (Jazz: 469240)
    * Made map set list grid able to be tabbed into (Jazz: 469240)
    * Added aria-labels to tree items, and aria-labels and tooltips to tree flags.
    * Added better arial-labels and either tooltips, placeholder text, label tags to autosuggest fields. (Jazz: 469395)
    * Added placeholder text to Description Value field in edit concept. (Jazz: 469395)
    * Added more complete descriptions to the aria labels in the concept and mapping editors. In some instances a more detailed description isn't possible if it's a new entry. (Jazz: 469387, 469403)


* 2017/02/17 - 1.64
    * Fixed refset CSV export so data is shown and is not encoded. Also fixed paging issues on grid so all results can be accessed and true total row number is displayed (jazz: 369888)
    * Fixed issue with mapping item template fields or matching calculated fields (ie: Source Code and Target Code) all having the same column name.

* 2017/02/16 - 1.63
    * Added changes to support multiple view parameters to taxonomy and concept viewer
    * Mapping Qualifier and it's values renamed (jazz: 440248)
    * IPO Template created and available to be assigned in the "Add more fields to Map Items" dialog (jazz: 462456)
    * Mapping fields renamed and pulled dynamically from concepts (jazz: 440195)

* 2017/02/09 - 1.62
    * Renamed 'Mapping Qualifier' field to 'Equivalence Type' (Jazz: 440248)
    * Now pulling Equivalence Type' mapping item field options from the appropriate concepts (Jazz: 440248)
    * Added option to UIHelper.createSelectFieldString to create empty option tags
    * Fixed autosuggest field so if you clear the field completely it will clear out the underlying value
    * Renamed some map set fields and pulled IDs from metadata instead of hardcoding.
    * Added 'Source' or 'Target' to mapset calculated column labels

* 2017/02/08 - 1.61
	* Intermediate test build

* 2017/02/03 - 1.60
    * Updated mapping to allow item field order to be chosen and calculated fields to be added to map items. Both occur only on mapset create. (Jazz: 444802, 430117)

* 2017/01/26 - 1.59
    * Changed so errors in attached sememe processing don't kill the app.
    * Removed hours and minutes from Mapping Effective Date so that it will update properly
    * Komet gets the aitc environment hash from prisme and displays the environment next to the version
    * Refactored much of the user preferences code to make it more maintainable

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
