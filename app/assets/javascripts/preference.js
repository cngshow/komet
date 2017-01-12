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
                    location.replace(gon.routes.komet_dashboard_dashboard_path);
                }
            },
            close: function() {
                form[ 0 ].reset();

            }
        });

        dialog.parent().children().children(".ui-dialog-titlebar-close").remove();

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
            console.log(colormodule);
            console.log(colorpath);
            console.log(colorrefsets);
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


    return {

        initialize: init,
        addRefsetRow: addRefsetRow,
        deleteRefsetFieldRow: deleteRefsetFieldRow,
        removecolor:removecolor,
        setShape:setShape,
        getShapeName:getShapeName


    };

})();