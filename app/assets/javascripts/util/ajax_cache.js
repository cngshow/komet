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
//might add this in later when there is more to optimize
var AjaxCache = (function () {
    var cache = new Map();
    //console.log("A new cache was born!");
    function fetch(path, params, callback) {
    //    console.log("path is " + path);
    //    console.log("params is " + JSON.stringify(params));
        var key = {};
        key.url = path;
        key.parameters = params;
       // console.log("cache is +" + JSON.stringify(cache[key]));
        if(cache.get(key) === undefined){
            console.log("NOT Returning from the cache!!");
            $.get(path, params, function (data) {
                cache.set(key, data);
      //          console.log("Setting data in the cache!");
                callback(data);
            });
        }
        else {
        //    console.log("Returning from the cache!!");
            callback(cache.get(key));
        }
    }

    return {
        fetch: fetch
    };
})();
