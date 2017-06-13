import React from 'react';

const MessageBox = ({
	message
}) => {
	return(
		<div className="message-box">
			<h2 className="bg-blue">
				{
					message
				}
			</h2>
		</div>
	);
};

export default MessageBox;