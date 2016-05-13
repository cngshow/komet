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
            height: 500,
            width: 550,
            dialogClass: "no-close",
            show: {
                effect: "blind",
                duration: 1000
            },
            hide: {
                effect: "explode",
                duration: 1000
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
            var getcoordinates = "";
            var descriptiontypepreferences= "";
            var dialectassemblagepreferences="";
            $.get( gon.routes.taxonomy_get_coordinates_path, function( getcoordinates_results ) {
                $( "#komet_concept_language" ).val(getcoordinates_results.languageCoordinate.language);
                descriptiontypepreferences = getcoordinates_results.languageCoordinate.dialectAssemblagePreferences;
                dialectassemblagepreferences= getcoordinates_results.languageCoordinate.descriptionTypePreferences;

                // Gets list of all the dialect based on constant uuid value
                populateControls('description_type',gon.IsaacMetadataAuxiliary.DIALECT_ASSEMBLAGE.uuids[0].uuid,descriptiontypepreferences)

                // Gets list of all the description type based on constant uuid value
                populateControls('dialecttbl',gon.IsaacMetadataAuxiliary.DESCRIPTION_TYPE.uuids[0].uuid,dialectassemblagepreferences)


            });

        });

        // Gets list of all the languages based on constant uuid value
        var uuidParams =  "?uuid=" +  gon.IsaacMetadataAuxiliary.LANGUAGE.uuids[0].uuid;
        // make an ajax call to get the data
        $.get(gon.routes.taxonomy_get_concept_languages_dialect_path + uuidParams, function( results ) {
            $.each(results.children,function(index,value) {
                $("#komet_concept_language").append($("<option />").val(value.conChronology.conceptSequence).text(value.conChronology.description));
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
            var description_values =""
            var dialect_values =""
            var language_values=$( "#komet_concept_language" ).val();
            var params = ""

            $('input[name=description_type]').each(function() {
                description_values += this.value + ',' ;
            });
            $('input[name=dialect_txt]').each(function() {
                dialect_values += this.value + ',' ;
            });

            dialect_values = dialect_values.substring(0  ,dialect_values.length -1); // removing comma from end of the string
            description_values = description_values.substring(0  ,description_values.length -1);// removing comma from end of the string

            params = {language: language_values , dialectPrefs: dialect_values ,descriptionTypePrefs:description_values} ;

            $.get( gon.routes.taxonomy_get_coordinatestoken , params, function( results ) {
            });

            dialog.dialog( "close" );
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

            $.each(items, function(i, val){
                if($.inArray(val, items_used) < 0)
                    items_compared.push(val);
            });
            // create rows that match coordination id with users pref coordination id
            for (var i = 0, count = get_default_values_id.length; i < count; i++) {
                counter = counter + 1;
                for(var j = 0; j < items_used.length; j++)
                {
                    if( parseInt(get_default_values_id[i].id) === parseInt(items_used[j]) )
                    {
                        renderTbl( get_default_values_id,counter,tablename,i);
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


    function renderTbl(value,counter,tblname,index)
    {
        var tr = document.createElement("TR");
        tr.setAttribute("id", "myTr" + counter);
        tr.setAttribute("data-cnt",counter);
        document.getElementById(tblname).appendChild(tr);

        var td1 = document.createElement("TD");
        td1.innerHTML ='<a  href="#"  class="change-rank up" data-icon="&#9650;"></a>&nbsp<a  href="#"  class="change-rank down" data-icon="&#9660;"></a>';
        document.getElementById("myTr" + counter).appendChild(td1);

        var td2 = document.createElement("TD");
        td2.innerHTML = value[index].description;
        document.getElementById("myTr" + counter).appendChild(td2);

        var td3 = document.createElement("TD");
        td3.innerHTML ='<input   type="hidden" name="description_type" id="rank_"' + counter + '" size="2" value="' + value[index].id + '" />';
        document.getElementById("myTr" + counter).appendChild(td3);

    }


    return {

        initialize: init,
        renderTbl: renderTbl

    };

})();