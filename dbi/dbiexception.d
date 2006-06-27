/**
 * Copyright: LGPL
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
	 *	
	 * Throws:
	 *	DBIException on invalid arguments.
	 */
	this (char[] msg, ...) {
		super("DBIException: " ~ msg);
		for (size_t i = 0; i < _arguments.length; i++) {
			if (_arguments[i] == typeid(char[])) {
				sql = va_arg!(char[])(_argptr);
			} else if (_arguments[i] == typeid(int)) {
				specificCode = va_arg!(int)(_argptr);
			} else if (_arguments[i] == typeid(uint)) {
				specificCode = va_arg!(uint)(_argptr);
			} else if (_arguments[i] == typeid(long)) {
				specificCode = va_arg!(long)(_argptr);
			}else if (_arguments[i] == typeid(ErrorCode)) {
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