/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.Exception;

private import tango.core.Vararg : va_arg;
public import dbi.ErrorCode;

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
	/+this (char[] msg, ...) {
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
	}+/
	
	this(char[] msg)
	{
		super(msg);
	}
	
	this(char[] msg, char[] sql)
	{
		this.sql = sql;
		
		this(msg);
	}
	
	this(char[] msg, char[] sql, ErrorCode dbiCode)
	{
		this.dbiCode = dbiCode;
		this(msg,sql);
	}
	
	this(char[] msg, long specificCode, ErrorCode dbiCode)
	{
		this.specificCode = specificCode;
		this.dbiCode = dbiCode;
		
		this(msg);
	}
	
	this(char[] msg, char[] sql, long specificCode, ErrorCode dbiCode)
	{
		this.sql = sql;
		this.specificCode = specificCode;
		this.dbiCode = dbiCode;
		
		this(msg);
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
	char[] getSql () {
		return sql;
	}
	
	char[] toString() {
		auto msg = super.toString;
		if(sql.length) msg ~= " SQL: " ~ sql;
		return msg;
	}

	private:
	char[] sql;
	long specificCode = 0;
	ErrorCode dbiCode = ErrorCode.Unknown;
}
