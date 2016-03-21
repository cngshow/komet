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
var SvgHelper = (function () {

    function startDiagram(svgId, conceptID)
 {
     if (!conceptID) {
         conceptID = ConceptsModule.getCurrentConceptId();
     }
     var route = gon.routes.logic_graph_version_path.replace(":id", conceptID.toString());
     AjaxCache.fetch(route,{},function(data){
       //  console.log("data  " + JSON.stringify(data))
      drawConceptDiagram(svgId,data)
     })
 }
    function drawConceptDiagram(svgId ,data) {


        var id = "#" + svgId;
        $(id).svg();
        var svg = $(id).svg('get');

        loadDefs(svg);

        var x = 10;
        var y = 10;
        var maxX = 10;
        var rect1 = drawSctBox(svg, 10, 10, data.referencedConceptDescription, 0, "sct-primitive-concept");
        x = x + 90;
        y = y + rect1.getBBox().height + 40;
        var circle1;
        if (data.rootLogicNode.children[0].nodeSemantic.name == "SUFFICIENT_SET") {
            circle1 = drawSubsumedByNode(svg, x, y);
        } else {
            circle1 = drawEquivalentNode(svg, x, y);
        }
        connectElements(svg, rect1, circle1, 'bottom-50', 'left');
        x = x + 55;
        var circle2 = drawConjunctionNode(svg, x, y);
        connectElements(svg, circle1, circle2, 'right', 'left', 'LineMarker');

        x = x + 40;
        y = y - 18;
        maxX = ((maxX < x) ? x : maxX);
        $.each(toArray(data.rootLogicNode.children[0].children[0]), function(i, field) {


            var splitstring = field.split(',')
            var maxnumber =0;
            for (i = 0; i < splitstring.length; i++) {

                var field  = splitstring[i];
                var splitval = field.split('~')
                if (splitval.length > 0)
                {

                    if (splitval[1]=="CONCEPT")
                    {
                        var conceptconnect = splitstring[i +2].split('~')

                        var rectParent = drawSctBox(svg, x, y, splitstring[i +3].split('~')[1] , conceptconnect[1], 'sct-defined-concept');

                        connectElements(svg, circle2, rectParent, 'center', 'left', 'ClearTriangle');
                        y = y + rectParent.getBBox().height + 25;
                        maxX = ((maxX < x + rectParent.getBBox().width + 50) ? x + rectParent.getBBox().width + 50 : maxX);

                    }
                    if (splitval[1] == "ROLE_SOME") {

                       var conceptconnect = splitstring[i +1].split('~')
                       var rectAttr = drawSctBox(svg, x, y, splitval[1],'', "sct-attribute");
                        connectElements(svg, circle2, rectAttr, 'center', 'left');
                       var rectTarget = drawSctBox(svg, x + rectAttr.getBBox().width + 50, y, splitstring[i +1].split('~')[1],conceptconnect[2], 'sct-defined-concept');
                      connectElements(svg, rectAttr, rectTarget, 'right', 'left');
                      y = y + rectTarget.getBBox().height + 25;
                      maxX = ((maxX < x + rectAttr.getBBox().width + 50 + rectTarget.getBBox().width + 50) ? x + rectAttr.getBBox().width + 50 + rectTarget.getBBox().width + 50 : maxX);
                        maxnumber = maxnumber +1;
                       if (maxnumber > 1)
                       {
                        y = y  + 15;
                           maxnumber=0;
                            var groupNode = drawAttributeGroupNode(svg, x, y);
                            connectElements(svg, circle2, groupNode, 'center', 'left');
                            var conjunctionNode = drawConjunctionNode(svg, x + 55, y);
                            connectElements(svg, groupNode, conjunctionNode, 'right', 'left');
                                sctClass = "sct-defined-concept";

                                var rectRole = drawSctBox(svg, x + 85, y - 18, splitstring[1],'',"sct-attribute");
                                connectElements(svg, conjunctionNode, rectRole, 'center', 'left');
                                var rectRole2 = drawSctBox(svg, x + 85 + rectRole.getBBox().width + 30, y - 18, splitstring[i +1],conceptconnect[2], sctClass);
                                connectElements(svg, rectRole, rectRole2, 'right', 'left');
                                y = y + rectRole2.getBBox().height + 25;
                                maxX = ((maxX < x + 85 + rectRole.getBBox().width + 30 + rectRole2.getBBox().width + 50) ? x + 85 + rectRole.getBBox().width + 30 + rectRole2.getBBox().width + 50 : maxX);
                       }
                    }
                  //  if (splitval[1] == "AND") {
                    //    var circle2 = drawConjunctionNode(svg, x, y);
                      //  connectElements(svg, circle1, circle2, 'right', 'left', 'LineMarker');
                    //}


                }
            }






        });






        //currentConcept = concept;
        //currentSvgId = svgId;
    }

    function toArray(obj) {
        var result = [];
        var result2 = []
        var counter =0;
        for (var prop in obj) {
            var value = obj[prop];
            if (prop != 'expandables')
            {
                if (typeof value === 'object') {
                    result.push(' '+  toArray(value) );
                    if (prop == 'nodeSemantic')
                    {
                        if ( typeof obj["connectorTypeConceptDescription"] != 'undefined')
                        {
                            result.push('ConceptconnectorType~'+ obj["connectorTypeConceptDescription"] + '~' + obj["connectorTypeConceptSequence"] );
                        }
                    }
                } else {
                    if (prop != 'enumId' && prop != 'connectorTypeConceptDescription' && prop != 'connectorTypeConceptSequence')
                    {
                        result.push( prop + '~'+  value  );
                    }
                }

            }
        }
        return result;

    }


    function loadDefs(svg) {

        var defs = svg.defs('SctDiagramsDefs');
        blackTriangle = svg.marker(defs, 'BlackTriangle', 0, 0, 20, 20, {
            viewBox: '0 0 22 20',
            refX: '0',
            refY: '10',
            markerUnits: 'strokeWidth',
            markerWidth: '8',
            markerHeight: '6',
            fill: 'black',
            stroke: 'black',
            strokeWidth: 2
        });
        svg.path(blackTriangle, 'M 0 0 L 20 10 L 0 20 z');

        clearTriangle = svg.marker(defs, 'ClearTriangle', 0, 0, 20, 20, {
            viewBox: '0 0 22 20',
            refX: '0',
            refY: '10',
            markerUnits: 'strokeWidth',
            markerWidth: '8',
            markerHeight: '8',
            fill: 'white',
            stroke: 'black',
            strokeWidth: 2
        });
        svg.path(clearTriangle, 'M 0 0 L 20 10 L 0 20 z');

        lineMarker = svg.marker(defs, 'LineMarker', 0, 0, 20, 20, {
            viewBox: '0 0 22 20',
            refX: '0',
            refY: '10',
            markerUnits: 'strokeWidth',
            markerWidth: '8',
            markerHeight: '8',
            fill: 'white',
            stroke: 'black',
            strokeWidth: 2
        });
        svg.path(lineMarker, 'M 0 10 L 20 10');
    }

    function drawSctBox(svg, x, y, label, sctid, cssClass) {
        //console.log("In svg: " + label + " " + sctid + " " + cssClass);
        var idSequence = 0;
        // x,y coordinates of the top-left corner
        var testText = "Test";
        if (label && sctid) {
            if (label.length > sctid.toString().length) {
                testText = label;
            } else {
                testText = sctid.toString();
            }
        } else if (label) {
            testText = label;
        } else if (sctid) {
            testText = sctid.toString();
        }
        var fontFamily = '"Helvetica Neue",Helvetica,Arial,sans-serif';
        //var fontFamily = 'sans-serif';
        var tempText = svg.text(x, y, testText, {fontFamily: fontFamily, fontSize: '12', fill: 'black'});
        var textHeight = tempText.getBBox().height;
        var textWidth = tempText.getBBox().width;
        textWidth = Math.round(textWidth * 1.2);
        svg.remove(tempText);

        var rect = null;
        var widthPadding = 20;
        var heightpadding = 25;

        if (!sctid || !label) {
            heightpadding = 15;
        }

        if (cssClass == "sct-primitive-concept") {
            rect = svg.rect(x, y, textWidth + widthPadding, textHeight + heightpadding, {
                id: 'rect' + idSequence,
                fill: '#99ccff',
                stroke: '#333',
                strokeWidth: 2
            });
        } else if (cssClass == 'sct-defined-concept') {
            rect = svg.rect(x - 2, y - 2, textWidth + widthPadding + 4, textHeight + heightpadding + 4, {
                fill: 'white',
                stroke: '#333',
                strokeWidth: 1
            });
            var innerRect = svg.rect(x, y, textWidth + widthPadding, textHeight + heightpadding, {
                id: 'rect' + idSequence,
                fill: '#ccccff',
                stroke: '#333',
                strokeWidth: 1
            });
        } else if (cssClass == 'sct-attribute') {
            rect = svg.rect(x - 2, y - 2, textWidth + widthPadding + 4, textHeight + heightpadding + 4, 18, 18, {
                fill: 'white',
                stroke: '#333',
                strokeWidth: 1
            });
            var innerRect = svg.rect(x, y, textWidth + widthPadding, textHeight + heightpadding, 18, 18, {
                id: 'rect' + idSequence,
                fill: '#ffffcc',
                stroke: '#333',
                strokeWidth: 1
            });
        } else if (cssClass == 'sct-slot') {
            rect = svg.rect(x, y, textWidth + widthPadding, textHeight + heightpadding, {
                id: 'rect' + idSequence,
                fill: '#99ccff',
                stroke: '#333',
                strokeWidth: 2
            });
        } else {
            rect = svg.rect(x, y, textWidth + widthPadding, textHeight + heightpadding, {
                id: 'rect' + idSequence,
                fill: 'white',
                stroke: 'black',
                strokeWidth: 1
            });
        }

        if (sctid && label) {
            svg.text(x + 10, y + 16, sctid.toString(), {fontFamily: fontFamily, fontSize: '10', fill: 'black'});
            svg.text(x + 10, y + 31, label, {fontFamily: fontFamily, fontSize: '12', fill: 'black'});
        } else if (label) {
            svg.text(x + 10, y + 18, label, {fontFamily: fontFamily, fontSize: '12', fill: 'black'});
        } else if (sctid) {
            svg.text(x + 10, y + 18, sctid.toString(), {fontFamily: fontFamily, fontSize: '12', fill: 'black'});
        }

        idSequence++;
        $('rect').click(function (evt) {
            console.log(evt.target);
        });

        return rect;
    }

    function connectElements(svg, fig1, fig2, side1, side2, endMarker) {
        var rect1cx = fig1.getBBox().x;
        var rect1cy = fig1.getBBox().y;
        var rect1cw = fig1.getBBox().width;
        var rect1ch = fig1.getBBox().height;

        var rect2cx = fig2.getBBox().x;
        var rect2cy = fig2.getBBox().y;
        var rect2cw = fig2.getBBox().width;
        var rect2ch = fig2.getBBox().height;

        var markerCompensantion1 = 15;
        var markerCompensantion2 = 15;

        switch (side1) {
            case 'top':
                originY = rect1cy;
                originX = rect1cx + (rect1cw / 2);
                break;
            case 'bottom':
                originY = rect1cy + rect1ch;
                originX = rect1cx + (rect1cw / 2);
                break;
            case 'left':
                originX = rect1cx - markerCompensantion1;
                originY = rect1cy + (rect1ch / 2);
                break;
            case 'right':
                originX = rect1cx + rect1cw;
                originY = rect1cy + (rect1ch / 2);
                break;
            case 'bottom-50':
                originY = rect1cy + rect1ch;
                originX = rect1cx + 40;
                break;
            default:
                originX = rect1cx + (rect1cw / 2);
                originY = rect1cy + (rect1ch / 2);
                break;
        }

        switch (side2) {
            case 'top':
                destinationY = rect2cy;
                destinationX = rect2cx + (rect2cw / 2);
                break;
            case 'bottom':
                destinationY = rect2cy + rect2ch;
                destinationX = rect2cx + (rect2cw / 2);
                break;
            case 'left':
                destinationX = rect2cx - markerCompensantion2;
                destinationY = rect2cy + (rect2ch / 2);
                break;
            case 'right':
                destinationX = rect2cx + rect2cw;
                destinationY = rect2cy + (rect2ch / 2);
                break;
            case 'bottom-50':
                destinationY = rect2cy + rect2ch;
                destinationX = rect2cx + 50;
                break;
            default:
                destinationX = rect2cx + (rect2cw / 2);
                destinationY = rect2cy + (rect2ch / 2);
                break;
        }

        if (endMarker == null) endMarker = 'BlackTriangle';

        polyline1 = svg.polyline([[originX, originY],
                [originX, destinationY], [destinationX, destinationY]]
            , {id: 'poly1', fill: 'none', stroke: 'black', strokeWidth: 2, 'marker-end': 'url(#' + endMarker + ')'});

    }

    function drawAttributeGroupNode(svg, x, y) {
        circle = svg.circle(x, y, 20, {fill: 'white', stroke: 'black', strokeWidth: 2});
        return circle;
    }

    function drawConjunctionNode(svg, x, y) {
        circle = svg.circle(x, y, 10, {fill: 'black', stroke: 'black', strokeWidth: 2});
        return circle;
    }

    function drawEquivalentNode(svg, x, y) {
        g = svg.group();
        svg.circle(g, x, y, 20, {fill: 'white', stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 7, y - 5, x + 7, y - 5, {stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 7, y, x + 7, y, {stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 7, y + 5, x + 7, y + 5, {stroke: 'black', strokeWidth: 2});
        return g;
    }

    function drawSubsumedByNode(svg, x, y) {
        g = svg.group();
        svg.circle(g, x, y, 20, {fill: 'white', stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 7, y - 8, x + 7, y - 8, {stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 7, y + 3, x + 7, y + 3, {stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 6, y - 8, x - 6, y + 3, {stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 7, y + 7, x + 7, y + 7, {stroke: 'black', strokeWidth: 2});
        return g;
    }

    function drawSubsumesNode(svg, x, y) {
        g = svg.group();
        svg.circle(g, x, y, 20, {fill: 'white', stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 7, y - 8, x + 7, y - 8, {stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 7, y + 3, x + 7, y + 3, {stroke: 'black', strokeWidth: 2});
        svg.line(g, x + 6, y - 8, x + 6, y + 3, {stroke: 'black', strokeWidth: 2});
        svg.line(g, x - 7, y + 7, x + 7, y + 7, {stroke: 'black', strokeWidth: 2});
        return g;
    }

    return {
        drawConceptDiagram: drawConceptDiagram,
        startDiagram: startDiagram
    };
})();
