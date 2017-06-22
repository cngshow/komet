import React from 'react';

const Modal = (props) => (
  <span>
    <div
      className={`modal fade modal-wide${props.open ? " in" : ""}`}
      style={{ display: props.open ? "block" : "none" }}>
      data-backdrop="static"
      role="dialog"
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
