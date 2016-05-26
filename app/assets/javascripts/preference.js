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
    function init() {


        var dialog, form

        dialog = $( "#dialog-form" ).dialog({
            autoOpen: false,
            closeOnEscape: false,
            position: ["bottom",70],
            height: 600,
            width: 550,
            dialogClass: "no-close",
            show: {
                effect: "blind",
                duration: 100
            },
            hide: {
                effect: "blind",
                duration: 100
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

        form = dialog.find( "form" ).on( "submit", function( event ) {
            event.preventDefault();
            applyChanges();
        });

        $("#settings").on( "click", function() {
            dialog.dialog( "open" );
            //Get default goordinates
            document.getElementById('loadingdiv').style.display ="block";
            var getcoordinates = "";
            var descriptiontypepreferences= "";
            var dialectassemblagepreferences="";
            var allowedstates =[];


            populateColormodule('');
            populateColorpath('');


            // Gets list of all the languages based on constant uuid value
            var uuidParams =  "?uuid=" +  gon.IsaacMetadataAuxiliary.LANGUAGE.uuids[0].uuid;
            // make an ajax call to get the data
            $.get(gon.routes.taxonomy_get_concept_languages_dialect_path + uuidParams, function( results ) {
                $.each(results.children,function(index,value) {
                    $("#komet_concept_language").append($("<option />").val(value.conChronology.conceptSequence).text(value.conChronology.description));
                });
            });

            document.getElementById('description_type').innerHTML ="";
            document.getElementById('dialecttbl').innerHTML ="";
            var tr = document.createElement("TR");
            tr.setAttribute("id", "heading1");
            tr.setAttribute("style", "background-color: #4f80d9;color:white");
            document.getElementById('description_type').appendChild(tr);

            var tr1 = document.createElement("TR");
            tr1.setAttribute("id", "heading2");
            tr1.setAttribute("style", "background-color: #4f80d9;color:white");
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

                 selectItemByValue(document.getElementById('komet_concept_language'),getcoordinates_results.languageCoordinate.language)
                descriptiontypepreferences = getcoordinates_results.languageCoordinate.dialectAssemblagePreferences;
                dialectassemblagepreferences= getcoordinates_results.languageCoordinate.descriptionTypePreferences;
                allowedstates =getcoordinates_results.stampCoordinate.allowedStates;
                // Gets list of all the dialect based on constant uuid value
                populateControls('dialecttbl',gon.IsaacMetadataAuxiliary.DIALECT_ASSEMBLAGE.uuids[0].uuid,dialectassemblagepreferences)

                // Gets list of all the description type based on constant uuid value
                populateControls('description_type',gon.IsaacMetadataAuxiliary.DESCRIPTION_TYPE.uuids[0].uuid,descriptiontypepreferences)

                //checked selected  values in status list
                selectAllowedstates(allowedstates);

                // this recreating color module table from session
                if (getcoordinates_results.colormodule != null)
                {
                    populateColormodule(getcoordinates_results.colormodule);
                }

                // this recreating path color  table from session
               if (getcoordinates_results.colorpath != null)
                {
                    populateColorpath(getcoordinates_results.colorpath);
                }

            });
            document.getElementById('loadingdiv').style.display ="none";
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
            var allowedStates=$('input[type=radio]:checked').val();
            var colormodule=[];
            var colorpath=[];
            var params = "";
            var moduleid="";

            $('input[name=description_type]').each(function() {
                description_values += this.value + ',' ;
            });
            $('input[name=dialecttbl]').each(function() {
                dialect_values += this.value + ',' ;
            });

            $('input[name=color_id]').each(function() {
                var splitvalue = this.id.split('~');
                colormodule.push({module_name:splitvalue[0],moduleid:splitvalue[1] ,colorid:this.value }) ;
            });
            $('input[name=colorpath]').each(function() {
                var splitvalue = this.id.split('~');
                colorpath.push({path_name:splitvalue[0],pathid:splitvalue[1] ,colorid:this.value }) ;
            });
            dialect_values = dialect_values.substring(0  ,dialect_values.length -1); // removing comma from end of the string
            description_values = description_values.substring(0  ,description_values.length -1);// removing comma from end of the string

            params = {language: language_values , dialectPrefs: dialect_values ,descriptionTypePrefs:description_values, allowedStates:allowedStates ,colormodule:colormodule,colorpath:colorpath} ;

            $.get( gon.routes.taxonomy_get_coordinatestoken_path , params, function( results ) {

            });

            dialog.dialog( "close" );
            location.replace(gon.routes.komet_dashboard_dashboard_path);
        }

    }
    function selectItemByValue(elmnt, value){

        for(var i=0; i < elmnt.options.length; i++)
        {
            if(elmnt.options[i].value == value)
                elmnt.selectedIndex = i;
        }
    }

// sets selected value of status radion button list
    function selectAllowedstates(values)
    {
        var statues ="";
        var inactive ="";
        for (var i = 0, count = values.length; i < count; i++) {
            if (values[i].name === 'Active')
            {
                statues = 'Active'
            }
            if (values[i].name === 'Inactive' &&  statues === 'Active')
            {
                statues += ',Inactive'
            }
            if (values[i].name === 'Inactive' &&  statues === "")
            {
                statues  = 'Inactive'
            }

        }
        $("input[name=status][value='" + statues + "']").attr('checked', 'checked');
    }


    function populateColorpath(pathvalue)
    {

        if (pathvalue === '')
        {
            // make an ajax call to get the data for path color list
            var   uuidParams =  "?uuid=" +  gon.IsaacMetadataAuxiliary.PATH.uuids[0].uuid;
            $.get(gon.routes.taxonomy_get_concept_languages_dialect_path + uuidParams, function( results ) {
                document.getElementById('listofpath').innerHTML ="";
                var colorpathheadingtr = document.createElement("TR");
                colorpathheadingtr.setAttribute("id", "colorpathheading");
                colorpathheadingtr.setAttribute("style", "background-color: #4f80d9;color:white")
                document.getElementById('listofpath').appendChild(colorpathheadingtr);

                var colorpathheadingtd1 = document.createElement("TD");
                colorpathheadingtd1.innerHTML ='Path';
                document.getElementById("colorpathheading").appendChild(colorpathheadingtd1);

                var colorpathheadingtd2 = document.createElement("TD");
                colorpathheadingtd2.innerHTML = 'Color';
                document.getElementById("colorpathheading").appendChild(colorpathheadingtd2);
                $.each(results.children,function(index,value) {
                    var tr = document.createElement("TR");
                    tr.setAttribute("id", "colorpathtr" + value.conChronology.conceptSequence);
                    document.getElementById('listofpath').appendChild(tr);

                    var td2 = document.createElement("TD");
                    td2.innerHTML = value.conChronology.description;
                    document.getElementById("colorpathtr" + value.conChronology.conceptSequence).appendChild(td2);

                    var td3 = document.createElement("TD");
                    td3.innerHTML = '<input name="colorpath" class="pathcolordemo" title="Click here to change color"  type="text" id="' + value.conChronology.description + '~' + value.conChronology.conceptSequence + '" size="6" style="height:40px" data-control="hue" value="" />';

                    document.getElementById("colorpathtr" + value.conChronology.conceptSequence).appendChild(td3);
                    $('.pathcolordemo').minicolors();
                });
            });
        }
        else {
            document.getElementById('listofpath').innerHTML ="";
            var colorpathheadingtr = document.createElement("TR");
            colorpathheadingtr.setAttribute("id", "colorpathheading");
            colorpathheadingtr.setAttribute("style", "background-color: #4f80d9;color:white")
            document.getElementById('listofpath').appendChild(colorpathheadingtr);

            var colorpathheadingtd1 = document.createElement("TD");
            colorpathheadingtd1.innerHTML ='Path';
            document.getElementById("colorpathheading").appendChild(colorpathheadingtd1);

            var colorpathheadingtd2 = document.createElement("TD");
            colorpathheadingtd2.innerHTML = 'Color';
            document.getElementById("colorpathheading").appendChild(colorpathheadingtd2);
            $.each(pathvalue, function (index, value) {
                var tr = document.createElement("TR");
                tr.setAttribute("id", "colorpathtr" + value.pathid);
                document.getElementById('listofpath').appendChild(tr);

                var td2 = document.createElement("TD");
                td2.innerHTML = value.path_name;
                document.getElementById("colorpathtr" + value.pathid).appendChild(td2);

                var td3 = document.createElement("TD");
                td3.innerHTML = '<input name="colorpath" class="pathcolordemo" title="Click here to change path color"  type="text" id="' + value.path_name + '~' + value.pathid + '" size="6" style="height:40px" data-control="hue" value="' + value.colorid + '" />';

                document.getElementById("colorpathtr" + value.pathid).appendChild(td3);
                $('.pathcolordemo').minicolors();
            });
        }



    }
    // adding row to color module table
    function populateColormodule(colormodule)
    {

        if(colormodule === '')
        {
            //Gets list of all the module.creating color module table from rest api call by passing constant uuid
            var uuidParams =  "?uuid=" +  gon.IsaacMetadataAuxiliary.MODULE.uuids[0].uuid;
            // make an ajax call to get the data for module color list
            $.get(gon.routes.taxonomy_get_concept_languages_dialect_path + uuidParams, function( results ) {
                document.getElementById('listofmodule').innerHTML ="";

                var colorheadingtr = document.createElement("TR");
                colorheadingtr.setAttribute("id", "colorheading");
                colorheadingtr.setAttribute("style", "background-color: #4f80d9;color:white")
                document.getElementById('listofmodule').appendChild(colorheadingtr);

                var colorheadingtd1 = document.createElement("TD");
                colorheadingtd1.innerHTML ='Module';
                document.getElementById("colorheading").appendChild(colorheadingtd1);

                var colorheadingtd2 = document.createElement("TD");
                colorheadingtd2.innerHTML = 'Color';
                document.getElementById("colorheading").appendChild(colorheadingtd2);

                $.each(results.children,function(index,value) {
                    var tr = document.createElement("TR");
                    tr.setAttribute("id", "colorTr" + value.conChronology.conceptSequence);
                    document.getElementById('listofmodule').appendChild(tr);

                    var td2 = document.createElement("TD");
                    td2.innerHTML = value.conChronology.description;
                    document.getElementById("colorTr" + value.conChronology.conceptSequence).appendChild(td2);

                    var td3 = document.createElement("TD");
                    td3.innerHTML = '<input name="color_id" class="demo" title="Click here to change color"  type="text" id="' + value.conChronology.description + '~' + value.conChronology.conceptSequence + '" size="6" style="height:40px" data-control="hue" value="" />';

                    document.getElementById("colorTr" + value.conChronology.conceptSequence).appendChild(td3);
                    $('.demo').minicolors();
                });

            });
        }
        else {
            document.getElementById('listofmodule').innerHTML ="";

            var colorheadingtr = document.createElement("TR");
            colorheadingtr.setAttribute("id", "colorheading");
            colorheadingtr.setAttribute("style", "background-color: #4f80d9;color:white")
            document.getElementById('listofmodule').appendChild(colorheadingtr);

            var colorheadingtd1 = document.createElement("TD");
            colorheadingtd1.innerHTML ='Module';
            document.getElementById("colorheading").appendChild(colorheadingtd1);

            var colorheadingtd2 = document.createElement("TD");
            colorheadingtd2.innerHTML = 'Color';
            document.getElementById("colorheading").appendChild(colorheadingtd2);
            $.each(colormodule, function (index, value) {
                var tr = document.createElement("TR");
                tr.setAttribute("id", "colorTr" + value.moduleid);
                document.getElementById('listofmodule').appendChild(tr);

                var td2 = document.createElement("TD");
                td2.innerHTML = value.module_name;
                document.getElementById("colorTr" + value.moduleid).appendChild(td2);

                var td3 = document.createElement("TD");
                td3.innerHTML = '<input name="color_id" class="demo" title="Click here to change color"  type="text" id="' + value.module_name + '~' + value.moduleid + '" size="6" style="height:40px" data-control="hue" value="' + value.colorid + '" />';

                document.getElementById("colorTr" + value.moduleid).appendChild(td3);
                $('.demo').minicolors();
            });

        }

    }

    // creates table of description type and dialect
    function populateControls(tablename,uuid,arrya_ids)
    {
        var counter =0;
        var get_default_ids =[];
        var get_default_values_id =[];

        if (tablename === 'dialecttbl')
        { counter =10;
        }
        uuidParams =  "?uuid=" + uuid;
        $.get( gon.routes.taxonomy_get_concept_languages_dialect_path + uuidParams, function( results ) {
            $.each(results.children,function(index,value) {
                get_default_ids.push(value.conChronology.conceptSequence);
                get_default_values_id.push({id:value.conChronology.conceptSequence,description:value.conChronology.description})
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

// add row to description type and dialect table
    function renderTbl(value,counter,tblname,index)
    {
        var tr = document.createElement("TR");
        tr.setAttribute("id", "Tr" + counter);
        tr.setAttribute("data-cnt",counter);
        document.getElementById(tblname).appendChild(tr);

        var td1 = document.createElement("TD");
        td1.innerHTML ='<a  href="#"  class="change-rank up" data-icon="&#9650;"></a>&nbsp<a  href="#"  class="change-rank down" data-icon="&#9660;"></a>';
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
        selectItemByValue: selectItemByValue



    };

})();