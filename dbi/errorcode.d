/**
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.ErrorCode;

private import dbi.DBIException;

/**
 *
 */
enum ErrorCode {
	NoError = 0,
	// Either DB-specific or not currently mapped to a standard error code.
	Unknown,
	// Errors in establishing a connection.
	SocketError,
	VersionError,
	ConnectionError,
	// Errors while logging in.
	UsernameError,
	PasswordError,
	// Errors in making a query (general).
	OutOfSync,
	NoData,
	InvalidData,
	InvalidQuery,
	// Errors in making a query (prepared statements).
	NotPrepared,
	ParamsNotBound,
	InvalidParams,
	// Miscellaneous
	LicenseError,
	NotImplemented,
	ServerError
}

/**
 * 
 */
char[] toString (ErrorCode error) {
	switch (error) {
		case (ErrorCode.NoError):
			return "No Error";
		case (ErrorCode.Unknown):
			return "Unknown";
		case (ErrorCode.SocketError):
			return "Socket Error";
		case (ErrorCode.ConnectionError):
			return "Connection Error";
		case (ErrorCode.VersionError):
			return "Version Mismatch Error";
		case (ErrorCode.UsernameError):
			return "Username Error";
		case (ErrorCode.PasswordError):
			return "Password Error";
		case (ErrorCode.OutOfSync):
			return "Out Of Sync";
		case (ErrorCode.NoData):
			return "No Data";
		case (ErrorCode.InvalidData):
			return "Invalid Data";
		case (ErrorCode.InvalidQuery):
			return "Invalid Query";
		case (ErrorCode.NotPrepared):
			return "Not Prepared";
		case (ErrorCode.ParamsNotBound):
			return "Params Not Bound";
		case (ErrorCode.InvalidParams):
			return "Invalid Params";
		case (ErrorCode.LicenseError):
			return "License Error";
		case (ErrorCode.NotImplemented):
			return "Not Implemented";
		case (ErrorCode.ServerError):
			return "Server Error";
		default:
	}
	throw new DBIException("Unknown error code.");
}