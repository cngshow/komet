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
const CloseButton = ({
  spinner,
  onClick
}) => {
  if (spinner)
    return null;

  return(
    <div className="close-x">
      <span
        className="close-x"
        aria-label="close button"
        aria-hidden="true"
        tabIndex="0"
        onClick={() => onClick() }
      >
        ×
      </span>
    </div>
  );
};
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
    const successMessage = 'Successfully imported XML. To see changes from imported concepts please refresh the taxonomy tree or any open concepts';
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
        this.setState({ success: successMessage, error: null, spinner: false });
      };
    })
    .catch(error => {
      form.reset();
      this.setState({ error: error.message, success: null, spinner: false });
    });
  };
  componentDidUpdate(){
    $('input[name="file"]').focus();
  };
  componentDidMount() {
    //508 xml import
    $(document).on('keydown', '.submit.xml-import-button', function(e){
      var e = getEvent(e);
      var keyCode = getKeyCode(e);

      if (e.keyCode == 9 && !e.shiftKey) {
        e.preventDefault();
        $('span.close-x').focus();
      };
    });
    $(document).on('keydown', 'span.close-x', function(e){
      var e = getEvent(e);
      var keyCode = getKeyCode(e);

      if (e.keyCode == 9 && e.shiftKey) {
        e.preventDefault();
        $('.submit.xml-import-button').focus();
      };
      if (e.keyCode == 13) {
        $('span.close-x').click();
      };
    });
    $(document).on('keydown', '[accept=".xml"]', function(e){
      var e = getEvent(e);
      var keyCode = getKeyCode(e);

      if (e.keyCode == 9 && e.shiftKey) {
        e.preventDefault();
        console.log('running')
        $('span.close-x').focus();
      };

      if (e.keyCode == 13) {
        $('input[accept=".xml"]').click();
      };
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
            <CloseButton
              spinner={this.state.spinner}
              onClick={() => this.cancelButton()}
            />
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
