/*
 Copyright Notice

 This is a work of the U.S. Government and is not subject to copyright
 protection in the United States. Foreign copyrights may apply.

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
var PreferenceModule = (function () {

    var refsetList = {};
    var refsetRows = [];
    var rowCount = 0;

    function loadPreferences() {

        Common.cursor_wait();

        // make an ajax call to get the data for user preferences and pass it the name of a partial file to render
        $.get(gon.routes.taxonomy_get_user_preference_info_path, {partial: 'komet_dashboard/userspreference'}, function (data) {

            try {

                var documentFragment = document.createRange().createContextualFragment(data);
                $('#komet_main_navigation').after(documentFragment);

                Common.cursor_auto();
            }
            catch (err) {

                console.log("*******  ERROR **********");
                console.log(err.message);
                Common.cursor_auto();
                throw err;
            }
        });
    }

    function init() {

        var stampDateField = $('#stamp_date');

        stampDateField.datetimepicker({
            showClear: true,
            showTodayButton: true,
            icons: {
                time: "fa fa-clock-o",
                date: "fa fa-calendar",
                up: "fa fa-arrow-up",
                down: "fa fa-arrow-down"
            }
        });

        refsetList = {};
        refsetRows = [];
        $.minicolors.defaults.position = 'bottom right';

        var dialog = $("#komet_user_preference_form");
        var form = dialog.find("form");

        // create the dialog form
        dialog.dialog({
            autoOpen: false,
            closeOnEscape: false,
            position: {my: "right top", at: "left bottom", of: "#komet_user_preference_link"},
            height: 650,
            width: 650,
            dialogClass: "no-close",
            show: {
                effect: "blind",
                duration: 50
            },
            hide: {
                effect: "blind",
                duration: 50
            },
            modal: true,
            buttons: {
                "Apply changes": applyChanges,
                Cancel: function() {
                    dialog.remove();
                }
            },
            close: function() {
                dialog.remove();
            }
        });

        dialog.parent().children().children(".ui-dialog-titlebar-close").remove();

        form.on("submit", function(event) {

            event.preventDefault();
            applyChanges();
        });


        //this event is used to rank the description type and dialect rows
        $(document).on("click", ".change-rank.up", function () {

            var original = $(this).closest("tr"),
                target = original.prev();

            if (target.length) {

                var targetCount = target.data("cnt");

                if (targetCount) {
                    original.after(target);
                }
            }
        });

        //this event is used to rank the description type and dialect rows
        $(document).on("click", ".change-rank.down", function () {

            var original = $(this).closest("tr"),
                target = original.next();

            if (target.length) {

                var targetCount = target.data("cnt");

                if (targetCount) {
                    original.before(target);
                }
            }
        });

        dialog.dialog("open");

        // get the hidden stamp date field value TODO - remove this field
        var stampDate = $('#stampedDt').val();

        if (stampDate !== 'latest') {
            stampDateField.data("DateTimePicker").date(moment(+stampDate));
        }

        $(document).on("click", "#applybtn", function () {

            var refsetSelectionField = $("#komet_preferences_refset_id").find("option:selected");
            addRefsetRow(refsetSelectionField.text(), $("#color_id").val(), refsetSelectionField.val(), $("#komet_preferences_shape_refset").val());
        });
    }

    // passes the users preference to set_coordinates_token api and creates set preference info in the session
    function applyChanges() {

        Common.cursor_wait();

        var description_values ="";
        var dialect_values ="";
        var language_values=$( "#komet_concept_language" ).val();

        // get the stamp_date and if it is not set then use the max long in gon
        var stamp_date = $('#stamp_date').find("input").val();

        if (stamp_date == '') {
            stamp_date = 'latest';
        } else {
            stamp_date = new Date(stamp_date).getTime().toString();
        }

        var allowedStates=$('input[name=status]:checked').val();
        var module_flags=[];
        var path_flags=[];
        var params = "";
        var moduleid="";
        var refset_flags = [];
        $('input[name=description_type]').each(function() {
            description_values += this.value + ',' ;
        });
        $('input[name=dialecttbl]').each(function() {
            dialect_values += this.value + ',' ;
        });

        $('input[name=module_id]').each(function() {
            module_flags.push({id: this.value, text: $("#komet_preferences_text_" + this.value).val(), color: $("#komet_preferences_color_" + this.value).val(), shape: $("#komet_preferences_shape_" + this.value).val()});
        });

        $('input[name=path_id]').each(function() {
            path_flags.push({id: this.value, text: $("#komet_preferences_text_" + this.value).val(), color: $("#komet_preferences_color_" + this.value).val(), shape: $("#komet_preferences_shape_" + this.value).val()});
        });

        $('input[name=colorrefsets]').each(function() {
            var splitvalue = this.id.split('~');
            refset_flags.push({text: splitvalue[0], id: splitvalue[1], color: this.value, shape: splitvalue[2]}) ;
        });

        dialect_values = dialect_values.substring(0, dialect_values.length -1); // removing comma from end of the string
        description_values = description_values.substring(0, description_values.length -1);// removing comma from end of the string
        console.log(module_flags);
        console.log(path_flags);
        console.log(refset_flags);
        params = {
            language: language_values,
            time: stamp_date,
            dialectPrefs: dialect_values,
            descriptionTypePrefs: description_values,
            allowedStates: allowedStates,
            module_flags: module_flags,
            path_flags: path_flags,
            refset_flags: refset_flags
        };

        $.post( gon.routes.taxonomy_set_coordinates_token_path, params, function( results ) {

            console.log(results);
            location.replace(gon.routes.komet_dashboard_dashboard_path);

        });
    }

    function deleteRefsetFieldRow(rowID){

        // $("#tr1").remove();
        // var index = refsetRows.indexOf('tr1');

        $("#tr" + rowID).remove();
        var index = refsetRows.indexOf(rowID);

        if (index > -1) {
            refsetRows.splice(index, 1);
        }
    }

    function addRefsetRow(refset, colorid, refsetsid, colorrefsetshape) {

        rowCount = rowCount + 1;
        // var rowID = window.performance.now();
        var tblrowcount = 0;
        var  founditem='false';
        $("#komet_preferences_refsets_table").find('tr').each(function (i, el) {
            var $tds = $(this).find('td');
            var    refsetsIds = $tds.eq(0).text();
            var    colorids = $tds.eq(1).text();
            var   colorrefsetshape = $tds.eq(2).text();
            var   refsetss = $tds.eq(3).text();
            tblrowcount = tblrowcount + 1
            if (parseInt(refsetsIds) === parseInt(refsetsid) && tblrowcount > 1)
            {
                // $tds.eq(1).setAttribute("style", "border:outset 1px black;width:15px;background-color:" + colorid );
                founditem='true';
                $tds.eq(1).css("background-color", "#" + colorid);
                $tds.eq(2).addClass(colorrefsetshape);
                return false;
            }
            else
            {
                founditem='false';
            }
        });

        if (founditem === 'false') {

            var refsetRow = document.createElement("tr");
            var refsetDeleteCell = document.createElement("td");
            var refsetColorCell = document.createElement("td");
            var refsetColorShapeCell = document.createElement("td");
            var refsetIDCell = document.createElement("td");
            var refsetCell = document.createElement("td");
            refsetRow.setAttribute("id", "tr" + rowCount);

            refsetIDCell.innerHTML = refsetsid;
            refsetCell.innerHTML ="&nbsp;&nbsp;" + refset;
            refsetColorShapeCell.innerHTML='<div class="' +  colorrefsetshape + '" ></div>';
            refsetColorCell.setAttribute("style", "border:outset 1px black;width:15px;background-color:" + colorid );
            refsetColorShapeCell.setAttribute("style", "text-align: center" );
            refsetDeleteCell.setAttribute("style", "text-align: center" );
            refsetDeleteCell.innerHTML='<a tooltip="remove refset" name="removeRow" onclick="PreferenceModule.deleteRefsetFieldRow(' + rowCount + ')">X</a>';
            refsetColorCell.innerHTML = '<input name="colorrefsets"  type="hidden" id="' + refset + '~' + refsetsid + '~' + colorrefsetshape + '" size="6" style="height:30px" data-control="hue" value=" ' + colorid + ' "  />';

            refsetRow.appendChild(refsetIDCell);
            refsetRow.appendChild(refsetColorCell);
            refsetRow.appendChild(refsetColorShapeCell);
            refsetRow.appendChild(refsetCell);
            refsetRow.appendChild(refsetDeleteCell);

            $("#komet_preferences_refsets_table").append(refsetRow);
        }
    }

    // sets selected shape into div tag
    function setShape(className, shapeName, flagID) {

        var shapeExample = $('#komet_preferences_shape_example_' + flagID);

        shapeExample.removeClass();
        shapeExample.addClass(className);
        shapeExample.html(shapeName);

        document.getElementById("komet_preferences_shape_" + flagID).value = className;
    }

    // based on the class list passed in return the appropriate shape name
    function getShapeName(className) {

        if (className == 'none') {
            return 'No shape';
        } else if (className == 'glyphicon glyphicon-stop') {
            return 'Square';
        } else if (className == 'glyphicon glyphicon-star') {
            return 'Star';
        } else if (className == 'fa fa-circle') {
            return 'Circle';
        } else if (className == 'glyphicon glyphicon-triangle-top') {
            return 'Triangle';
        } else if (className == 'glyphicon glyphicon-asterisk') {
            return 'Asterisk';
        }
    }

    //clear color value
    function removeColor(flagID) {

        var colorField = document.getElementById('komet_preferences_color_' + flagID);
        colorField.value="";
        colorField.style.backgroundColor ="";

        $("#komet_preferences_row_" + flagID ).find('.minicolors-swatch-color').css("background-color", "");
    }

    function getStampDate(){

        var stamp_date = $('#stamp_date').find("input").val();

        if (stamp_date == '') {
            return 'latest';
        } else {
            return new Date(stamp_date).getTime().toString();
        }
    }

    return {

        loadPreferences: loadPreferences,
        initialize: init,
        addRefsetRow: addRefsetRow,
        deleteRefsetFieldRow: deleteRefsetFieldRow,
        removeColor: removeColor,
        setShape: setShape,
        getShapeName: getShapeName,
        getStampDate: getStampDate
    };

})();