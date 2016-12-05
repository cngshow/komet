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
    var rowCount=0;
    function init() {

        refsetList = {};
        refsetRows = [];
        $.minicolors.defaults.position = 'bottom right';
        var dialog, form;

        dialog = $("#komet_user_preference_form").dialog({
            autoOpen: false,
            closeOnEscape: false,
            position: { my: "right top", at: "left bottom", of: "#komet_user_preference_link" },
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
                    dialog.dialog( "close" );
                }
            },
            close: function() {
                form[ 0 ].reset();

            }
        });

        dialog.parent().children().children(".ui-dialog-titlebar-close").remove();

        // Gets list of all the languages based on constant uuid value
        var uuidParams =  "?uuid=" +  gon.IsaacMetadataAuxiliary.LANGUAGE.uuids[0].uuid;
        // make an ajax call to get the data for language on option tab
        $.get(gon.routes.taxonomy_get_concept_children_path + uuidParams, function( results ) {
            $.each(results,function(index,value) {
                $("#komet_concept_language").append($("<option />").val(value.conChronology.identifiers.sequence).text(value.conChronology.description));
            });
        });

        populateColormodule(''); // populate color module
        populateColorpath(''); // populate color path

        // get the list of refsets to populate the refsets dropdown
        $.get(gon.routes.taxonomy_get_refset_list_path, function(refset_data) {
            refsetList = refset_data;
            createRefsetFieldRow();
        });


        form = dialog.find( "form" ).on( "submit", function( event ) {
            event.preventDefault();
            applyChanges();
        });

        $("#komet_user_preference_link").on( "click", function() {
            dialog.dialog( "open" );
            //Get default goordinates

            var getcoordinates = "";
            var descriptiontypepreferences= "";
            var dialectassemblagepreferences="";
            var allowedstates =[];

            document.getElementById('description_type').innerHTML ="";
            document.getElementById('dialecttbl').innerHTML ="";


            var tr = document.createElement("TR");
            tr.setAttribute("id", "heading1");
            tr.setAttribute("style", "background-color: #0000a2;color:white");
            document.getElementById('description_type').appendChild(tr);

            var tr1 = document.createElement("TR");
            tr1.setAttribute("id", "heading2");
            tr1.setAttribute("style", "background-color: #0000a2;color:white");
            document.getElementById('dialecttbl').appendChild(tr1);

            var td1 = document.createElement("TD");
            td1.innerHTML ='Rank';
            document.getElementById("heading1").appendChild(td1);

            var td2 = document.createElement("TD");
            td2.innerHTML = 'Dialect Preference';
            document.getElementById("heading1").appendChild(td2);

            var td4 = document.createElement("TD");
            td4.innerHTML ='Rank';
            document.getElementById("heading2").appendChild(td4);

            var td3 = document.createElement("TD");
            td3.innerHTML = 'Description Type';
            document.getElementById("heading2").appendChild(td3);

            $.get( gon.routes.taxonomy_get_coordinates_path, function( getcoordinates_results ) {
                var stamp_date = getcoordinates_results.taxonomyCoordinate.stampCoordinate.time;

                if (stamp_date !== gon.vhat_export_params.max_end_date) {
                    $('#stamp_date').data("DateTimePicker").date(moment(stamp_date));
                }

                selectItemByValue(document.getElementById('komet_concept_language'),getcoordinates_results.languageCoordinate.language);
                $("#komet_concept_language").val(getcoordinates_results.languageCoordinate.language);
                descriptiontypepreferences = getcoordinates_results.languageCoordinate.descriptionTypePreferences;
                dialectassemblagepreferences= getcoordinates_results.languageCoordinate.dialectAssemblagePreferences;
                allowedstates =getcoordinates_results.stampCoordinate.allowedStates;
                // Gets list of all the dialect based on constant uuid value
                populateControls('dialecttbl',gon.IsaacMetadataAuxiliary.DIALECT_ASSEMBLAGE.uuids[0].uuid,dialectassemblagepreferences);

                // Gets list of all the description type based on constant uuid value
                populateControls('description_type',gon.IsaacMetadataAuxiliary.DESCRIPTION_TYPE.uuids[0].uuid,descriptiontypepreferences);

                //checked selected  values in status list
                selectAllowedstates(allowedstates);

                // this recreating color module table from session
                if (getcoordinates_results.colormodule != null)
                {
                    document.getElementById('listofmodule').innerHTML = "";
                    populateColormodule(getcoordinates_results.colormodule);
                }

                // this recreating path color  table from session
                if (getcoordinates_results.colorpath != null) {
                    document.getElementById('listofpath').innerHTML ="";
                    populateColorpath(getcoordinates_results.colorpath);
                }
                if (getcoordinates_results.colorrefsets != null) {

                    document.getElementById('komet_preferences_refsets_table').innerHTML ="";

                    var colorheadingtr = document.createElement("TR");
                    colorheadingtr.setAttribute("id", "colorrefset");
                    colorheadingtr.setAttribute("style", "background-color: #0000a2;color:white;text-align: center")
                    document.getElementById('komet_preferences_refsets_table').appendChild(colorheadingtr);

                    var colorheadingtd0 = document.createElement("TD");
                    colorheadingtd0.innerHTML ='ID';
                    document.getElementById("colorrefset").appendChild(colorheadingtd0);

                    var colorheadingtd1 = document.createElement("TD");
                    colorheadingtd1.innerHTML ='Color';
                    document.getElementById("colorrefset").appendChild(colorheadingtd1);

                    var colorheadingtd2 = document.createElement("TD");
                    colorheadingtd2.innerHTML = 'Refset';
                    document.getElementById("colorrefset").appendChild(colorheadingtd2);

                    var colorheadingtd3 = document.createElement("TD");
                    colorheadingtd3.innerHTML = 'Delete';
                    document.getElementById("colorrefset").appendChild(colorheadingtd3);

                    $.each(getcoordinates_results.colorrefsets, function (index, value) {
                        addRefsetRow(value.refsets_name,value.colorid,value.refsetsid,value.colorshape)
                    });

                }

            });

            $(document).on("click", "#applybtn", function (ev) {
                var refsetname=$("#komet_preferences_refset_id option:selected").text();
                var refsetsid=$("#komet_preferences_refset_id option:selected").val();
                var colorid=$("#color_id").val();
                var colorrefsetshape = $("#colorrefsetshape").val();
                addRefsetRow(refsetname,colorid,refsetsid,colorrefsetshape);
            });


        });


        //this events are used to rank the description type and dialect rows
        $(document).on("click", ".change-rank.up", function (ev) {
            var $original = $(this).closest("tr"),
                $target = $original.prev();

            if ($target.length) {
                var cnt = $original.data('cnt'),
                    targetcnt = $target.data("cnt");
                if (targetcnt) {
                    $original.after($target);
                }
            }
        });

        //this events are used to rank the description type and dialect rows
        $(document).on("click", ".change-rank.down", function (ev) {
            var $original = $(this).closest("tr"),
                $target = $original.next();
            if ($target.length) {
                var cnt = $original.data('cnt'),
                    targetcnt = $target.data("cnt");
                if (targetcnt) {
                    $original.before($target);
                }
            }
        });

        // passes the users preference to get coordinatetoken api and creates sessions
        function applyChanges() {
            var description_values ="";
            var dialect_values ="";
            var language_values=$( "#komet_concept_language" ).val();

            // get the stamp_date and if it is not set then use the max long in gon
            var stamp_date = $("#stamp_date").find("input").val();
            if (stamp_date == '') {
                stamp_date = 'latest';
            } else {
                stamp_date = new Date(stamp_date).getTime().toString();
            }

            var allowedStates=$('input[name=status]:checked').val();
            var colormodule=[];
            var colorpath=[];
          //  var colormoduleshapes=[];
            var params = "";
            var moduleid="";
            var colorrefsets = [];
            $('input[name=description_type]').each(function() {
                description_values += this.value + ',' ;
            });
            $('input[name=dialecttbl]').each(function() {
                dialect_values += this.value + ',' ;
            });

            $('input[name=color_id]').each(function() {
                var splitvalue = this.id.split('~');
                if (splitvalue[0] != "color_id")
                { var getshapecntlID= "colormoduleshape" + splitvalue[1];
                    colormodule.push({module_name:splitvalue[0],moduleid:splitvalue[1] ,colorid:this.value,colorshape:document.getElementById(getshapecntlID).value}) ;
                }

            });
            $('input[name=colorpath]').each(function() {
                var splitvalue = this.id.split('~');
                var getshapecntlID= "colorpathshape" + splitvalue[1];
                colorpath.push({path_name:splitvalue[0],pathid:splitvalue[1] ,colorid:this.value,colorshape:document.getElementById(getshapecntlID).value}) ;
            });

            $('input[name=colorrefsets]').each(function() {
                var splitvalue = this.id.split('~');
                colorrefsets.push({refsets_name:splitvalue[0],refsetsid:splitvalue[1],colorid:this.value,colorshape:splitvalue[2]}) ;
            });
           // $('input[name=colormodule_shape]').each(function() {
             //   var splitvalue = this.id.split('~');
               // colormoduleshapes.push({moduleid:splitvalue[1] ,shapeclass:this.value }) ;
            //});

            dialect_values = dialect_values.substring(0, dialect_values.length -1); // removing comma from end of the string
            description_values = description_values.substring(0, description_values.length -1);// removing comma from end of the string

            params = {
                language: language_values,
                stamp_date: stamp_date,
                dialectPrefs: dialect_values,
                descriptionTypePrefs: description_values,
                allowedStates: allowedStates,
                colormodule: colormodule,
                colorpath: colorpath,
                colorrefsets: colorrefsets
            };
            $.post( gon.routes.taxonomy_get_coordinatestoken_path, params, function( results ) {
                console.log(results);
                dialog.dialog( "close" );
                location.replace(gon.routes.komet_dashboard_dashboard_path);
            });
        }
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

    // create a new select field for choosing a refset and color picker
    function createRefsetFieldRow(){

        var options = "";
        var refsetSelect = '<label  for="komet_preferences_refset_id">Select Refset: </label><select style="width:270px"  id="komet_preferences_refset_id">';

        Object.keys(refsetList).forEach( function(refsetID) {
            options += '<option value="' + refsetID + '">' + refsetList[refsetID] + '</option>';
        });

        refsetSelect += options + '</select>';
        document.getElementById('getdd').innerHTML =refsetSelect;

        var refsetShape='';
        var td4 = document.createElement("TD");
        var shapeCntlId =  "'colorrefsetshape'"  ;
        var displayShapeDiv =  "crefsetshape_0"  ;
        refsetShape = PreferenceModule.createShapedropdown(displayShapeDiv , 0 , shapeCntlId,'none');

        document.getElementById('getrefsetshape').innerHTML =refsetShape;

        //  refsetRows.push(rowID);
        document.getElementById('komet_preferences_refsets_table').innerHTML ="";

        var colorheadingtr = document.createElement("TR");
        colorheadingtr.setAttribute("id", "colorrefset");
        colorheadingtr.setAttribute("style", "background-color: #0000a2;color:white;text-align: center")
        document.getElementById('komet_preferences_refsets_table').appendChild(colorheadingtr);

        var colorheadingtd0 = document.createElement("TD");
        colorheadingtd0.innerHTML ='ID';
        document.getElementById("colorrefset").appendChild(colorheadingtd0);

        var colorheadingtd1 = document.createElement("TD");
        colorheadingtd1.innerHTML ='Color';
        document.getElementById("colorrefset").appendChild(colorheadingtd1);

        var colorheadingtd2 = document.createElement("TD");
        colorheadingtd2.innerHTML ='Shape';
        document.getElementById("colorrefset").appendChild(colorheadingtd2);

        var colorheadingtd3 = document.createElement("TD");
        colorheadingtd3.innerHTML = 'Refset';
        document.getElementById("colorrefset").appendChild(colorheadingtd3);

        var colorheadingtd4 = document.createElement("TD");
        colorheadingtd4.innerHTML = 'Delete';
        document.getElementById("colorrefset").appendChild(colorheadingtd4);

    }

    function addRefsetRow(refset,colorid,refsetsid,colorrefsetshape)    {
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
            if (founditem === 'false')
            {

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


    // sets selected value of status radion button list
    function selectAllowedstates(values)    {
        var statues ="";
        var inactive ="";

        for (var i = 0, count = values.length; i < count; i++) {
            if (values[i].name === 'Active')
            {
                statues = 'Active'
            }
            if (values[i].name === 'Inactive' &&  statues === 'Active')
            {
                statues = statues +  ',Inactive'
            }
            if (values[i].name === 'Inactive' &&  statues === "")
            {
                statues  = 'Inactive'
            }

        }
        $("input[name=status][value='" + statues + "']").attr('checked', 'checked');
    }


    function populateColorpath(pathvalue)    {
       if (pathvalue === '')
        {
            // make an ajax call to get the data for path color list
            var   uuidParams =  "?uuid=" +  gon.IsaacMetadataAuxiliary.PATH.uuids[0].uuid;
            $.get(gon.routes.taxonomy_get_concept_children_path + uuidParams, function( results ) {
                document.getElementById('listofpath').innerHTML ="";
                var colorpathheadingtr = document.createElement("TR");
                colorpathheadingtr.setAttribute("id", "colorpathheading");
                colorpathheadingtr.setAttribute("style", "background-color: #0000a2;color:white");
                document.getElementById('listofpath').appendChild(colorpathheadingtr);

                var colorpathheadingtd1 = document.createElement("TD");
                colorpathheadingtd1.innerHTML ='Path';
                colorpathheadingtd1.setAttribute("style", "width:40%")
                document.getElementById("colorpathheading").appendChild(colorpathheadingtd1);

                var colorpathheadingtd2 = document.createElement("TD");
                colorpathheadingtd2.innerHTML = 'Color';
                colorpathheadingtd2.setAttribute("style", "width:25%")
                document.getElementById("colorpathheading").appendChild(colorpathheadingtd2);

                var colorpathheadingtd3 = document.createElement("TD");
                colorpathheadingtd3.innerHTML = 'Shape';
                colorpathheadingtd3.setAttribute("style", "width:30%")
                document.getElementById("colorpathheading").appendChild(colorpathheadingtd3);

                $.each(results,function(index,value) {
                    var tr = document.createElement("TR");
                    tr.setAttribute("id", "colorpathtr" + value.conChronology.identifiers.sequence);
                    document.getElementById('listofpath').appendChild(tr);

                    var label = 'lbl_colorpathtr_' + value.conChronology.identifiers.sequence;
                    var td2 = document.createElement("TD");
                    td2.setAttribute("id", label);
                    td2.innerHTML = value.conChronology.description;

                    document.getElementById("colorpathtr" + value.conChronology.identifiers.sequence).appendChild(td2);

                    var colorrowid = "'" + value.conChronology.description + "~" + value.conChronology.identifiers.sequence + "','colorpathtr" + value.conChronology.identifiers.sequence + "'";

                    var td3 = document.createElement("TD");
                    td3.innerHTML = '<a title="clear color" style="padding:2px;color:red" aria-labelledby="' + label + '" onclick="PreferenceModule.removecolor(' + colorrowid + ')">X</a>&nbsp;'
                        +'<input name="colorpath" class="pathcolordemo" title="Click here to change color" aria-labelledby="' + label +'" type="text" '
                        + 'id="' + value.conChronology.description + '~' + value.conChronology.identifiers.sequence + '" size="6" style="height:30px" data-control="hue" value="" />';
                    document.getElementById("colorpathtr" + value.conChronology.identifiers.sequence).appendChild(td3);

                    var td4 = document.createElement("TD");
                    var shapeCntlId =  "'colorpathshape" + value.conChronology.identifiers.sequence + "'" ;
                    var displayShapeDiv =  "cpathshape_" + value.conChronology.identifiers.sequence  ;
                    td4.innerHTML = PreferenceModule.createShapedropdown(displayShapeDiv , value.conChronology.identifiers.sequence , shapeCntlId,'none');
                    document.getElementById("colorpathtr" + value.conChronology.identifiers.sequence).appendChild(td4);

                    $('.pathcolordemo').minicolors();
                });
            });
        }
        else {
            document.getElementById('listofpath').innerHTML ="";
            var colorpathheadingtr = document.createElement("TR");
            colorpathheadingtr.setAttribute("id", "colorpathheading");
            colorpathheadingtr.setAttribute("style", "background-color: #0000a2;color:white")
            document.getElementById('listofpath').appendChild(colorpathheadingtr);

            var colorpathheadingtd1 = document.createElement("TD");
            colorpathheadingtd1.innerHTML ='Path';
            colorpathheadingtd1.setAttribute("style", "width:40%")
            document.getElementById("colorpathheading").appendChild(colorpathheadingtd1);

            var colorpathheadingtd2 = document.createElement("TD");
            colorpathheadingtd2.innerHTML = 'Color';
            colorpathheadingtd2.setAttribute("style", "width:25%")
            document.getElementById("colorpathheading").appendChild(colorpathheadingtd2);

           var colorpathheadingtd3 = document.createElement("TD");
           colorpathheadingtd3.innerHTML = 'Shape';
           colorpathheadingtd3.setAttribute("style", "width:30%")
           document.getElementById("colorpathheading").appendChild(colorpathheadingtd3);

            $.each(pathvalue, function (index, value) {
                var tr = document.createElement("TR");
                tr.setAttribute("id", "colorpathtr" + value.pathid);
                document.getElementById('listofpath').appendChild(tr);

                var label = 'lbl_colorpathtr_' + value.pathid;
                var td2 = document.createElement("TD");
                td2.innerHTML = value.path_name;
                td2.setAttribute("id", label);
                document.getElementById("colorpathtr" + value.pathid).appendChild(td2);

                var colorrowid = "'" + value.path_name + "~" + value.pathid + "','colorpathtr" + value.pathid + "'";

                var td3 = document.createElement("TD");
                td3.innerHTML = '<a title="clear color" style="padding:2px;color:red" aria-labelledby="' + label + '" onclick="PreferenceModule.removecolor(' + colorrowid + ')">X</a>&nbsp;'
                    +'<input name="colorpath" class="pathcolordemo" title="Click here to change path color"  aria-labelledby="' + label +'" type="text" '
                    + 'id="' + value.path_name + '~' + value.pathid + '" size="6" style="height:30px" data-control="hue" value="' + value.colorid + '" />';
                document.getElementById("colorpathtr" + value.pathid).appendChild(td3);

                var td4 = document.createElement("TD");
                var shapeCntlId =  "'colorpathshape" + value.pathid + "'" ;
                var displayShapeDiv =  "cpathshape_" + value.pathid  ;
                td4.innerHTML = PreferenceModule.createShapedropdown(displayShapeDiv , value.pathid , shapeCntlId,value.colorshape);
                document.getElementById("colorpathtr" + value.pathid).appendChild(td4);


                $('.pathcolordemo').minicolors();
            });
        }



    }
    // adding row to color module table
    function populateColormodule(colormodule)    {

        if(colormodule === '')
        {
            document.getElementById('listofmodule').innerHTML ="";

            var colorheadingtr = document.createElement("TR");
            colorheadingtr.setAttribute("id", "colorheading");
            colorheadingtr.setAttribute("style", "background-color: #0000a2;color:white")
            document.getElementById('listofmodule').appendChild(colorheadingtr);

            var colorheadingtd1 = document.createElement("TD");
            colorheadingtd1.innerHTML ='Module';
            colorheadingtd1.setAttribute("style", "width:40%")
            document.getElementById("colorheading").appendChild(colorheadingtd1);

            var colorheadingtd2 = document.createElement("TD");
            colorheadingtd2.innerHTML = 'Color';
            colorheadingtd2.setAttribute("style", "width:30%")
            document.getElementById("colorheading").appendChild(colorheadingtd2);
            var colorheadingtd3 = document.createElement("TD");
            colorheadingtd3.innerHTML = 'Shape';
            colorheadingtd3.setAttribute("style", "width:30%")
            document.getElementById("colorheading").appendChild(colorheadingtd3);
            //Gets list of all the module.creating color module table from rest api call by passing constant uuid
            var uuidParams =  "?uuid=" +  gon.IsaacMetadataAuxiliary.MODULE.uuids[0].uuid;
            // make an ajax call to get the data for module color list
            $.get(gon.routes.taxonomy_get_concept_children_path + uuidParams, function( results ) {
                $.each(results,function(index,value) {
                    var tr = document.createElement("TR");
                    tr.setAttribute("id", "colorTr" + value.conChronology.identifiers.sequence);
                    document.getElementById('listofmodule').appendChild(tr);

                    var label = 'lbl_colorTr_' + value.conChronology.identifiers.sequence;
                    var td2 = document.createElement("TD");
                    td2.innerHTML = value.conChronology.description;
                    td2.setAttribute("id", label);
                    document.getElementById("colorTr" + value.conChronology.identifiers.sequence).appendChild(td2);

                    var colorrowid = "'" + value.conChronology.description + "~" + value.conChronology.identifiers.sequence + "','colorTr" + value.conChronology.identifiers.sequence + "'";
                    var td3 = document.createElement("TD");
                    td3.innerHTML = '<a title="clear color" style="padding:2px;color:red" aria-labelledby="' + label + '" onclick="PreferenceModule.removecolor(' + colorrowid + ')">X</a>'
                        + '<input name="color_id" class="demo" title="Click here to change color"  aria-labelledby="' + label + '" type="text" '
                        + 'id="' + value.conChronology.description + '~' + value.conChronology.identifiers.sequence + '" size="6" style="height:30px" data-control="hue" value="" />&nbsp;';
                    document.getElementById("colorTr" + value.conChronology.identifiers.sequence).appendChild(td3);

                    var td4 = document.createElement("TD");
                    var shapeCntlId =  "'colormoduleshape" + value.conChronology.identifiers.sequence + "'" ;
                    var displayShapeDiv =  "cshape_" + value.conChronology.identifiers.sequence  ;
                    td4.innerHTML = PreferenceModule.createShapedropdown(displayShapeDiv , value.conChronology.identifiers.sequence , shapeCntlId,'none');
                    document.getElementById("colorTr" + value.conChronology.identifiers.sequence).appendChild(td4);
                    $('.demo').minicolors();
                });

            });
        }
        else {
            document.getElementById('listofmodule').innerHTML ="";
            var colorheadingtr = document.createElement("TR");
            colorheadingtr.setAttribute("id", "colorheading");
            colorheadingtr.setAttribute("style", "background-color: #0000a2;color:white")
            document.getElementById('listofmodule').appendChild(colorheadingtr);

            var colorheadingtd1 = document.createElement("TD");
            colorheadingtd1.innerHTML ='Module';
            colorheadingtd1.setAttribute("style", "width:40%")
            document.getElementById("colorheading").appendChild(colorheadingtd1);

            var colorheadingtd2 = document.createElement("TD");
            colorheadingtd2.innerHTML = 'Color';
            colorheadingtd2.setAttribute("style", "width:30%")
            document.getElementById("colorheading").appendChild(colorheadingtd2);

            var colorheadingtd3 = document.createElement("TD");
            colorheadingtd3.innerHTML = 'Shape';
            colorheadingtd3.setAttribute("style", "width:30%")
            document.getElementById("colorheading").appendChild(colorheadingtd3);

            $.each(colormodule, function (index, value) {
                var tr = document.createElement("TR");
                tr.setAttribute("id", "colorTr" + value.moduleid);
                document.getElementById('listofmodule').appendChild(tr);

                var label = 'lbl_colorTr_' + value.moduleid;
                var td2 = document.createElement("TD");
                td2.innerHTML = value.module_name;
                td2.setAttribute("id", label);
                document.getElementById("colorTr" + value.moduleid).appendChild(td2);

                var colorrowid = "'" + value.module_name + "~" + value.moduleid + "','colorTr" + value.moduleid + "'";
                var td3 = document.createElement("TD");
                td3.innerHTML = '<a title="clear color"  style="padding:2px;color:red" aria-labelledby="' + label + '" onclick="PreferenceModule.removecolor(' + colorrowid + ')">X</a>&nbsp;'
                    + '<input name="color_id" class="demo" title="Click here to change color" aria-labelledby="' + label + '" type="text" '
                    + 'id="' + value.module_name + '~' + value.moduleid + '" size="6" style="height:30px" data-control="hue" value="' + value.colorid + '" />';
                document.getElementById("colorTr" + value.moduleid).appendChild(td3);

                var td4 = document.createElement("TD");
                var shapeCntlId =  "'colormoduleshape" + value.moduleid + "'" ;
                var displayShapeDiv =  "cshape_" + value.moduleid  ;
                td4.innerHTML = PreferenceModule.createShapedropdown(displayShapeDiv , value.moduleid , shapeCntlId,value.colorshape);
                document.getElementById("colorTr" + value.moduleid).appendChild(td4);
                $('.demo').minicolors();
            });

        }

    }

    // sets selected shape into div tag
    function setShape(classname,shapes,id,inputid)    {
        var selectedshape = '#' + id ;
        var inputids='#' + inputid;

        $(selectedshape).removeClass("noshape");
        $(selectedshape).removeClass("glyphicon glyphicon-stop");
        $(selectedshape).removeClass( "glyphicon glyphicon-star");
        $(selectedshape).removeClass( "fa fa-circle");
        $(selectedshape).removeClass( "glyphicon glyphicon-triangle-top");
        $(selectedshape).removeClass( "glyphicon glyphicon-asterisk");
        $(selectedshape).html(shapes);
        $(selectedshape).addClass(classname);
        document.getElementById(inputid).value =classname;


    }

    /// creates shape dropdown
    function createShapedropdown(displayShapeDiv,conceptSequence,shapeCntlId,value)    {
        var shapedd='';
        shapedd ='<div class="dropdown" ><div class="' +  value + '" style="display: inline-block" id="' +  displayShapeDiv + '">' + PreferenceModule.getShapeName(value) + '</div>';
        shapedd = shapedd + '<input name="colormodule_shape" value="' +  value + '"  type="hidden" id=' + shapeCntlId + '  />';
        shapedd = shapedd + '<span  class="dropdown-toggle" data-toggle="dropdown" role="button" aria-haspopup="true" id="shapeid" aria-expanded="false">';
        shapedd = shapedd + '<span class="caret"></span></span><ul class="dropdown-menu"   aria-label="select shape">';
        shapedd = shapedd + '<li>';
        shapedd = shapedd + '<a style="display: inline-block" onclick="PreferenceModule.setShape(' + "'none'" + "," + "'None'" + ",'" +  displayShapeDiv  + "'," + shapeCntlId + ')" href="#">No Shape</a></li>';
        shapedd = shapedd + '<li aria-hidden="true"  class="glyphicon glyphicon-stop" >';
        shapedd = shapedd + '<a style="display: inline-block" onclick="PreferenceModule.setShape(' + "'glyphicon glyphicon-stop'" + "," + "'Square'" + ",'" +  displayShapeDiv  + "'," + shapeCntlId + ')" href="#">Square</a></li>';
        shapedd = shapedd + '<li aria-hidden="true" class="glyphicon glyphicon-star">';
        shapedd = shapedd + '<a href="#" style="display: inline-block" onclick="PreferenceModule.setShape(' + "'glyphicon glyphicon-star'" + "," + "'Star'" +  ",'" +  displayShapeDiv  + "'," + shapeCntlId + ')">Star</a></li>';
        shapedd = shapedd + '<li aria-hidden="true" class="glyphicon glyphicon-triangle-top">';
        shapedd = shapedd + '<a href="#" style="display: inline-block" onclick="PreferenceModule.setShape(' + "'glyphicon glyphicon-triangle-top'" + "," + "'Triangle'" +  ",'" +  displayShapeDiv  + "'," + shapeCntlId + ')">Triangle</a></li>';
        shapedd = shapedd + '<li aria-hidden="true" class="glyphicon glyphicon-asterisk">';
        shapedd = shapedd + '<a href="#" style="display: inline-block" onclick="PreferenceModule.setShape(' + "'glyphicon glyphicon-asterisk'" + "," + "'Asterisk'" +  ",'" +  displayShapeDiv  + "'," + shapeCntlId + ')">Asterisk</a></li>';
        shapedd = shapedd + '<li aria-hidden="true" class="fa fa-circle">';
        shapedd = shapedd + '<a href="#" style="display: inline-block" onclick="PreferenceModule.setShape(' + "'fa fa-circle'" + "," + "'Circle'" +  ",'" +  displayShapeDiv  + "'," + shapeCntlId + ')">Circle</a></li>';
        shapedd = shapedd + '</ul></div>';

        return shapedd;
    }
     function getShapeName(classname)
     {

         if (classname == 'none')
             return 'No shape';
         else if (classname == 'glyphicon glyphicon-stop')
             return 'Square';
         else
         if (classname == 'glyphicon glyphicon-star')
             return 'Star';
         else
         if (classname == 'fa fa-circle')
             return 'Circle';
         else
         if (classname == 'glyphicon glyphicon-triangle-top')
             return 'Triangle';
         else
         if (classname == 'glyphicon glyphicon-asterisk')
             return 'Asterisk';


        // return 'Square';
     }
    //clear color value
    function removecolor(controlid,rowid)    {

        var colorid = "#" + controlid;
        document.getElementById(controlid).value="";
        document.getElementById(controlid).style.backgroundColor ="";
        $("#" + rowid ).find('.minicolors-swatch-color').css("background-color","");
    }

    // creates table of description type and dialect
    function populateControls(tablename,uuid,arrya_ids)    {
        var counter =0;
        var get_default_ids =[];
        var get_default_values_id =[];

        if (tablename === 'dialecttbl')
        { counter =10;
        }
        uuidParams =  "?uuid=" + uuid;
        $.get( gon.routes.taxonomy_get_concept_children_path + uuidParams, function( results ) {
            $.each(results,function(index,value) {
                get_default_ids.push(value.conChronology.identifiers.sequence);
                get_default_values_id.push({id:value.conChronology.identifiers.sequence,description:value.conChronology.description})
            });

            var items = get_default_ids;
            var items_used = arrya_ids;
            var items_compared = Array();
            var items_adddescription_id =[];

            $.each(items, function(i, val){
                if($.inArray(val, items_used) < 0)
                    items_compared.push(val);
            });
            // create rows that match coordination id with users pref coordination id
            for (var i = 0, count = items_used.length; i < count; i++) {
                counter = counter + 1;
                for(var j = 0; j < get_default_values_id.length; j++)
                {
                    if( parseInt(items_used[i]) === parseInt(get_default_values_id[j].id)  )
                    {
                        renderTbl(get_default_values_id,counter,tablename,j);
                    }
                }
            }
            //create row that coordination id is not part of users pref
            for (var i = 0, count = get_default_values_id.length; i < count; i++) {
                counter = counter + 1;
                for(var j = 0; j < items_compared.length; j++)
                {
                    if( parseInt(get_default_values_id[i].id) === parseInt(items_compared[j]) )
                    {
                        renderTbl( get_default_values_id,counter,tablename,i);
                    }
                }
            }

        });
    }

    function selectItemByValue(elmnt, value){
       for(var i=0; i < elmnt.options.length; i++)
        {
            if(elmnt.options[i].value == value)
                elmnt.selectedIndex = i;
        }
    }

    // add row to description type and dialect table
    function renderTbl(value,counter,tblname,index)    {
        var tr = document.createElement("TR");
        tr.setAttribute("id", "Tr" + counter);
        tr.setAttribute("data-cnt",counter);
        document.getElementById(tblname).appendChild(tr);

        var td1 = document.createElement("TD");
        td1.innerHTML ='<a style="cursor: default"  class="change-rank up" data-icon="&#9650;"></a>&nbsp<a  style="cursor: default"   class="change-rank down" data-icon="&#9660;"></a>';
        document.getElementById("Tr" + counter).appendChild(td1);

        var td2 = document.createElement("TD");
        td2.innerHTML = value[index].description;
        document.getElementById("Tr" + counter).appendChild(td2);

        var td3 = document.createElement("TD");
        td3.innerHTML ='<input   type="hidden" name="' + tblname  + '" id="rank_"' + counter + '" size="2" value="' + value[index].id + '" />';
        document.getElementById("Tr" + counter).appendChild(td3);

    }


    return {

        initialize: init,
        renderTbl: renderTbl,
        populateColormodule: populateColormodule,
        populateColorpath: populateColorpath,
        populateControls: populateControls,
        selectAllowedstates: selectAllowedstates,
        selectItemByValue: selectItemByValue,
        createRefsetFieldRow:createRefsetFieldRow,
        addRefsetRow: addRefsetRow,
        deleteRefsetFieldRow: deleteRefsetFieldRow,
        removecolor:removecolor,
        setShape:setShape,
        createShapedropdown:createShapedropdown,
        getShapeName:getShapeName


    };

})();