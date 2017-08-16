import React from 'react';

const Modal = (props) => (
  <span>
    <div
      id="bootstrap-react-modal"
      className={`modal fade modal-wide${props.open ? " in" : ""}`}
      style={{ display: props.open ? "block" : "none" }}>
      <div className="modal-dialog">
        <div className="modal-content">
          { props.children }
        </div>
      </div>
    </div>

    { props.open ? <div className="modal-backdrop fade in"></div> : null }
  </span>
);

export default Modal;
