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

var ImportModule = (function ImportModule() {
  return {
    initialize: initialize,
  };

  function initialize() {
    $("#komet_import_link").click(show);
    $("#import_modal .cancel").click(close);
  }

  function show() {
    ModalFormValidatorModule.show_modal("import_modal");
  }

  function close() {
    ModalFormValidatorModule.reset_modal_form('import_modal_form');
    ModalFormValidatorModule.hide_modal('import_modal');
  }
})();

$(ImportModule.initialize);
