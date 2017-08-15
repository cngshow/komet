import React from 'react';
import Modal from './modal.jsx';
import MessageBox from './messageBox.jsx';
import ErrorBox from './errorBox.jsx';

const VhatXmlImportButtons = ({
  disable,
  onClose
}) => (
  <div>
    <button
      className="btn btn-default cancel xml-import-button"
      role="button"
      onClick={() => onClose()}
      disabled={disable}
    >
      Close
    </button>
    <button 
      type="submit" 
      role="button" 
      className="btn btn-default submit xml-import-button"
      disabled={disable}
    >
      Submit
    </button>
  </div>
);
export default class VhatXmlImport extends React.Component {
  /**
   * @param props - Comes from your rails view.
   * @param _railsContext - Comes from React on Rails
   */
  constructor(props, _railsContext) {
    super(props);
    this.state = {  };
  };
  cancelButton() {
    this.setState({ 
      open: false,
      success: null,
      error: null,
      spinner: false,
    });
  }; 
  onFormSubmit(form, body) {
    //https://github.com/github/fetch/issues/424 FOR CSRF TOKEN HEADERS
    this.setState({ spinner: true });
    const token = $('meta[name="csrf-token"]').attr('content');
    api(gon.routes.import_path, {
      method: 'POST',
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': token
      },
      body,
      credentials: 'same-origin'
    })
    .then(response => { 
      form.reset();
      if (!response) {
        this.setState({ success: "Successfully imported XML", error: null, spinner: false });
      };
    })
    .catch(error => {
      form.reset();
      this.setState({ error: error.message, success: null, spinner: false });
    });
  };
  render() {
    let fileInput;
    let form;

    return (
      <div className="vhat-import-container">
      	<button 
          onClick={() =>
            this.setState({ open: true })
          }
      		type="button"
      		className="komet-link-button" 
      		role="button" 
      		aria-label="VHAT XML Import" 
      		title="VHAT XML Import" 
      		id="komet_import_link"
            >
          	<div className="glyphicon glyphicon-import" title="VHAT XML Import">
          	</div>
        </button>

        <Modal open={this.state.open}>
          <div className="vha-import-wrapper">
            <form
              ref={ref => form = ref}
              onSubmit={ev => {
                ev.preventDefault();
                const body = new FormData();
                body.append('file', fileInput.files[0]);
                this.onFormSubmit(form, body);
              }}>
              <div className="modal-header">
                <h2 className="modal-title">VHAT XML Import</h2>
              </div>
              <div className="modal-body">
                {
                  this.state.spinner ? 
                    <div><div data-loader="circle"></div></div> :
                    <div>
                      { this.state.success ? <MessageBox message={ this.state.success } /> : null }
                      { this.state.error ? <ErrorBox error={ this.state.error } /> : null }
                      <h2 className="modal-title">Please choose file</h2>
                      <input 
                        ref={ref => fileInput = ref} 
                        type="file" 
                        accept=".xml" 
                        name="file" 
                        required
                        autoFocus
                      >
                      </input>
                    </div>
                }
              </div>
              <hr />
              <div>
                <div className="btn-bar">
                  <VhatXmlImportButtons 
                    disable={this.state.spinner} 
                    onClose={() => this.cancelButton() }
                  />
                </div>
              </div>
            </form>
          </div>
        </Modal>
      </div>
    );
  }
}

function api(url, options) {
  return fetch(url, options).then(response => {
    if (response.ok) {
      const contentType = response.headers.get("content-type");
      if (contentType.indexOf("application/json") !== -1) {
        return response.json();
      }
    } else {
      return response.json().then(error => { 
        throw new Error(error.errors.message) 
      });
    }
  });
}
