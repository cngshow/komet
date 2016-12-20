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

            var stamp_date = $('#stampedDt').val();

            if (stamp_date !== gon.vhat_export_params.max_end_date) {
                $('#stamp_date').data("DateTimePicker").date(moment(stamp_date));
            }
            $.get( gon.routes.taxonomy_get_coordinates_path, function( getcoordinates_results ) {
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

                    var colorheadingtd1 = document.createElement("TD");
                    colorheadingtd1.innerHTML ='Shape';
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
                var splimoduletvalue = this.id.split('~');
                if (splimoduletvalue[0] != "color_id")
                {
                    var getshapemodulecntlID= "colormoduleshape" + splimoduletvalue[1];
                    colormodule.push({module_name:splimoduletvalue[0],moduleid:splimoduletvalue[1] ,colorid:this.value,colorshape:document.getElementById(getshapemodulecntlID).value}) ;
                }

            });
            $('input[name=colorpath]').each(function() {
                var splitpathvalue = this.id.split('~');
                var getshapepathcntlID= "colorpathshape" + splitpathvalue[1];
                colorpath.push({path_name:splitpathvalue[0],pathid:splitpathvalue[1] ,colorid:this.value,colorshape:document.getElementById(getshapepathcntlID).value}) ;
            });

            $('input[name=colorrefsets]').each(function() {
                var splitvalue = this.id.split('~');
                colorrefsets.push({refsets_name:splitvalue[0],refsetsid:splitvalue[1],colorid:this.value,colorshape:splitvalue[2]}) ;
            });

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

            });
            dialog.dialog( "close" );
            location.replace(gon.routes.komet_dashboard_dashboard_path);
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

     // sets selected shape into div tag
    function setShape(classname,shapes,id,inputid)    {
        var selectedshape = '#' + id ;
        var inputids='#' + inputid;

        $(selectedshape).removeClass("None");
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
     function getShapeName(classname)  {
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

    function selectItemByValue(elmnt, value){
       for(var i=0; i < elmnt.options.length; i++)
        {
            if(elmnt.options[i].value == value)
                elmnt.selectedIndex = i;
        }
    }


    return {

        initialize: init,
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