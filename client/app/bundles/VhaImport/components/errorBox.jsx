import React from 'react';

const ErrorBox = ({
	error
}) => {
	return(
		<div className="error-box">
			<h2 className="bg-blue">
				{
					`Error: ${error}`
				}
			</h2>
		</div>
	);
};

export default ErrorBox;