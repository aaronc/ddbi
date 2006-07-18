/**
 * Authors: The D DBI project
 *
 * Version: 0.2.3
 *
 * Copyright: BSD license
 */
module dbi.DBIException;

private static import std.stdarg;
private import dbi.ErrorCode;

/**
 * This is the exception class used within all of D DBI.
 *
 * Some functions may also throw different types of exceptions when they access the
 * standard library, so be sure to also catch Exception in your code.
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
				sql = std.stdarg.va_arg!(char[])(_argptr);
			} else if (_arguments[i] == typeid(byte)) {
				specificCode = std.stdarg.va_arg!(byte)(_argptr);
			} else if (_arguments[i] == typeid(ubyte)) {
				specificCode = std.stdarg.va_arg!(ubyte)(_argptr);
			} else if (_arguments[i] == typeid(short)) {
				specificCode = std.stdarg.va_arg!(short)(_argptr);
			} else if (_arguments[i] == typeid(ushort)) {
				specificCode = std.stdarg.va_arg!(ushort)(_argptr);
			} else if (_arguments[i] == typeid(int)) {
				specificCode = std.stdarg.va_arg!(int)(_argptr);
			} else if (_arguments[i] == typeid(uint)) {
				specificCode = std.stdarg.va_arg!(uint)(_argptr);
			} else if (_arguments[i] == typeid(long)) {
				specificCode = std.stdarg.va_arg!(long)(_argptr);
			} else if (_arguments[i] == typeid(ulong)) {
				specificCode = cast(long)std.stdarg.va_arg!(ulong)(_argptr);
			} else if (_arguments[i] == typeid(ErrorCode)) {
				dbiCode = std.stdarg.va_arg!(ErrorCode)(_argptr);
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