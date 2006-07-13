/**
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.DBIException;

private import std.stdarg;
private import dbi.ErrorCode;

/**
 * This is the exception class used within all of D DBI.  At the moment, it assumes
 * that the database uses a numeric error code, which seems to be true for most of
 * them.  If that needs to be changed in the future to be more generic, that will
 * be done.
 */
class DBIException : Exception {
	/**
	 * Create a new DBIException.
	 */
	this () {
		this("Unknown Error.");
	}

	/**
	 * Create a new DBIException.
	 *
	 * Params:
	 *	msg = The message to report to the users.
	 *	
	 * Throws:
	 *	DBIException on invalid arguments.
	 */
	this (char[] msg, ...) {
		super("DBIException: " ~ msg);
		for (size_t i = 0; i < _arguments.length; i++) {
			if (_arguments[i] == typeid(char[])) {
				sql = va_arg!(char[])(_argptr);
			} else if (_arguments[i] == typeid(byte)) {
				specificCode = va_arg!(byte)(_argptr);
			} else if (_arguments[i] == typeid(ubyte)) {
				specificCode = va_arg!(ubyte)(_argptr);
			} else if (_arguments[i] == typeid(short)) {
				specificCode = va_arg!(short)(_argptr);
			} else if (_arguments[i] == typeid(ushort)) {
				specificCode = va_arg!(ushort)(_argptr);
			} else if (_arguments[i] == typeid(int)) {
				specificCode = va_arg!(int)(_argptr);
			} else if (_arguments[i] == typeid(uint)) {
				specificCode = va_arg!(uint)(_argptr);
			} else if (_arguments[i] == typeid(long)) {
				specificCode = va_arg!(long)(_argptr);
			} else if (_arguments[i] == typeid(ulong)) {
				specificCode = cast(long)va_arg!(ulong)(_argptr);
			} else if (_arguments[i] == typeid(ErrorCode)) {
				dbiCode = va_arg!(ErrorCode)(_argptr);
			} else {
				throw new DBIException("Invalid argument of type \"" ~ _arguments[i].toString() ~ "\" passed to the DBIException constructor.");
			}
		}
	}

	/**
	 * Get the database's DBI error code.
	 *
	 * Returns:
	 *	Database's DBI error code.
	 */
	ErrorCode getErrorCode () {
		return dbiCode;
	}

	/**
	 * Get the database's numeric error code.
	 *
	 * Returns:
	 *	Database's numeric error code.
	 */
	long getSpecificCode () {
		return specificCode;
	}

	/**
	 * Get the SQL statement that caused the error.
	 *
	 * Returns:
	 *	SQL statement that caused the error.
	 */
	char[] getSQL () {
		return sql;
	}
	
	private:
	char[] sql;
	long specificCode = 0;
	ErrorCode dbiCode = ErrorCode.Unknown;
}