/**
 * Authors: The D DBI project
 *
 * Version: 0.2.2
 *
 * Copyright: BSD license
 */
module dbi.odbc.OdbcDatabase;

// Almost every cast involving chars and SQLCHARs shouldn't exist, but involve bugs in
// WindowsAPI revision 144.  I'll see about fixing their ODBC and SQL files soon.
// WindowsAPI should also include odbc32.lib itself.

private import std.string;
private import dbi.Database, dbi.DBIException, dbi.Result;
private import dbi.odbc.OdbcResult;
private import win32.odbcinst, win32.sql, win32.sqlext, win32.sqltypes, win32.sqlucode, win32.windef;

pragma (lib, "odbc32.lib");

private SQLHENV environment;

/*
 * This is in the sql headers, but wasn't ported in WindowsAPI revision 144.
 */
private bool SQL_SUCCEEDED (SQLRETURN ret) {
	return (ret == SQL_SUCCESS || ret == SQL_SUCCESS_WITH_INFO) ? true : false;
}

static this () {
	// Note: The cast is a pseudo-bug workaround for WindowsAPI revision 144.
	if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_ENV, cast(SQLHANDLE)SQL_NULL_HANDLE, &environment))) {
		throw new DBIException("Unable to initialize the ODBC environment.");
	}
	// Note: The cast is a pseudo-bug workaround for WindowsAPI revision 144.
	if (!SQL_SUCCEEDED(SQLSetEnvAttr(environment, SQL_ATTR_ODBC_VERSION, cast(SQLPOINTER)SQL_OV_ODBC3, 0))) {
		throw new DBIException("Unable to set the ODBC environment to version 3.");
	}
}

static ~this () {
	if (!SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_ENV, environment))) {
		throw new DBIException("Unable to close the ODBC environment.");
	}
}

/**
 * An implementation of Database for use with the ODBC interface.
 *
 * Bugs:
 *	Database-specific error codes are not converted to ErrorCode.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class OdbcDatabase : Database {
	public:
	/**
	 * Create a new instance of OdbcDatabase, but don't connect.
	 */
	this () {
		if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_DBC, environment, &connection))) {
			throw new DBIException("Unable to create the ODBC connection.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
	}

	/**
	 * Create a new instance of OdbcDatabase and connect to a server.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] params, char[] username = null, char[] password = null) {
		this();
		connect(params, username, password);
	}

	/**
	 * Connect to a database using ODBC.
	 *
	 * This function will connect DSN-lessly if params has a "=" and with DSN
	 * otherwise.  For information on how to use connect DSN-lessly, see the
	 * ODBC documentation.
	 *
	 * Bugs:
	 *	Connecting DSN-lessly ignores username and password.
	 *
	 * Params:
	 *	params = The DSN to use or the connection parameters.
	 *	username = The _username to _connect with.
	 *	password = The _password to _connect with.
	 *
	 * Throws:
	 *	DBIException if there was an error connecting.
	 *
	 * Examples:
	 *	---
	 *	OdbcDatabase db = new OdbcDatabase();
	 *	db.connect("Data Source Name", "_username", "_password");
	 *	---
	 *
	 * See_Also:
	 *	The ODBC documentation included with the MDAC 2.8 SDK.
	 */
	override void connect (char[] params, char[] username = null, char[] password = null) {
		if (std.string.find(params, "=") > 0) {
			SQLCHAR[1024] buffer;
			if (!SQL_SUCCEEDED(SQLDriverConnect(connection, null, cast(SQLCHAR*)params, cast(SQLSMALLINT)params.length, buffer, buffer.length, null, SQL_DRIVER_COMPLETE))) {
				throw new DBIException("Unable to connect to the database.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		} else {
			if (!SQL_SUCCEEDED(SQLConnect(connection, cast(SQLCHAR*)params, cast(SQLSMALLINT)params.length, cast(SQLCHAR*)username, cast(SQLSMALLINT)username.length, cast(SQLCHAR*)password, cast(SQLSMALLINT)password.length))) {
				throw new DBIException("Unable to connect to the database.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		}

	}

	/**
	 * Close the current connection to the database.
	 *
	 * Throws:
	 *	DBIException if there was an error disconnecting.
	 *
	 *	DBIException if the ODBC connection handle couldn't be closed.
	 */
	override void close () {
		if (!SQL_SUCCEEDED(SQLDisconnect(connection))) {
			throw new DBIException("Unable to disconnect from the database.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
		if (!SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_DBC, connection))) {
			throw new DBIException("Unable to close an ODBC connection.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
	}

	/**
	 * Execute a SQL statement that returns no results.
	 *
	 * Params:
	 *	sql = The SQL statement to _execute.
	 *
	 * Throws:
	 *	DBIException if an ODBC statement couldn't be created.
	 *
	 *	DBIException if the SQL code couldn't be executed.
	 *
	 *	DBIException if there is an error while committing the changes.
	 *
	 *	DBIException if there is an error while rolling back the changes.
	 *
	 *	DBIException if an ODBC statement couldn't be destroyed.
	 */
	override void execute (char[] sql) {
		scope (exit)
			stmt = null;
		scope (exit)
			if (!SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_STMT, stmt))) {
				throw new DBIException("Unable to destroy an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		scope (failure) 
			if (!SQL_SUCCEEDED(SQLEndTran(SQL_HANDLE_DBC, connection, SQL_ROLLBACK))) {
				throw new DBIException("Unable to rollback after a query failure.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
			}
		scope (success) 
			if (!SQL_SUCCEEDED(SQLEndTran(SQL_HANDLE_DBC, connection, SQL_COMMIT))) {
				throw new DBIException("Unable to commit data after a successful query.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
			}
		if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_STMT, connection, &stmt))) {
			throw new DBIException("Unable to create an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
		if (!SQL_SUCCEEDED(SQLExecDirect(stmt, cast(SQLCHAR*)sql, sql.length))) {
			throw new DBIException("Unable to execute SQL code.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
		}
		
	}

	/**
	 * Query the database.
	 *
	 * Params:
	 *	sql = The SQL statement to execute.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 *
	 * Throws:
	 *	DBIException if an ODBC statement couldn't be created.
	 *
	 *	DBIException if the SQL code couldn't be executed.
	 *
	 *	DBIException if there is an error while committing the changes.
	 *
	 *	DBIException if there is an error while rolling back the changes.
	 *
	 *	DBIException if an ODBC statement couldn't be destroyed.
	 */
	override Result query (char[] sql) {
		scope (failure)
			if (!SQL_SUCCEEDED(SQLFreeHandle(SQL_HANDLE_STMT, stmt))) {
				throw new DBIException("Unable to destroy an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		scope (failure) 
			if (!SQL_SUCCEEDED(SQLEndTran(SQL_HANDLE_DBC, connection, SQL_ROLLBACK))) {
				throw new DBIException("Unable to rollback after a query failure.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
			}
		scope (success) 
			if (!SQL_SUCCEEDED(SQLEndTran(SQL_HANDLE_DBC, connection, SQL_COMMIT))) {
				throw new DBIException("Unable to commit data after a successful query.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
			}
		if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_STMT, connection, &stmt))) {
			throw new DBIException("Unable to create an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
		if (SQL_SUCCEEDED(SQLExecDirect(stmt, cast(SQLCHAR*)sql, sql.length))) {
			return new OdbcResult(stmt);
		} else {
			throw new DBIException("Unable to query the database.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
		}
	}

	/**
	 * Get the error code.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.  This will be
	 *	removed in version 0.3.0.
	 *
	 * Returns:
	 *	The database specific error code.
	 */
	deprecated override int getErrorCode () {
		return getLastErrorCode;
	}

	/**
	 * Get the error message.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.  This will be
	 *	removed in version 0.3.0.
	 *
	 * Returns:
	 *	The database specific error message.
	 */
	deprecated override char[] getErrorMessage () {
		return getLastErrorMessage();
	}

	/*
	 * Note: The following are not in the DBI API.
	 */

	/**
	 * Get a list of currently installed ODBC drivers.
	 *
	 * Returns:
	 *	A list of all the installed ODBC drivers.
	 */
	char[][] getDrivers () {
		SQLCHAR[][] driverList;
		SQLCHAR[512] driver;
		SQLCHAR[512] attr;
		SQLSMALLINT driverLength;
		SQLSMALLINT attrLength;
		SQLUSMALLINT direction = SQL_FETCH_FIRST;
		SQLRETURN ret = SQL_SUCCESS;

		while (SQL_SUCCEEDED(ret = SQLDrivers(environment, direction, driver, driver.length, &driverLength, attr, attr.length, &attrLength))) {
			direction = SQL_FETCH_NEXT;
			driverList ~= driver[0 .. driverLength] ~ cast(SQLCHAR[])" ~ " ~ attr[0 .. attrLength];
			if (ret == SQL_SUCCESS_WITH_INFO) {
				throw new DBIException("Data truncation occurred in the driver list.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		}
		return cast(char[][])driverList;
	}

	/**
	 * Get a list of currently available ODBC data sources.
	 *
	 * Returns:
	 *	A list of all the installed ODBC data sources.
	 */
	char[][] getDataSources () {
		SQLCHAR[][] dataSourceList;
		SQLCHAR[512] dsn;
		SQLCHAR[512] desc;
		SQLSMALLINT dsnLength;
		SQLSMALLINT descLength;
		SQLUSMALLINT direction = SQL_FETCH_FIRST;
		SQLRETURN ret = SQL_SUCCESS;

		while (SQL_SUCCEEDED(ret = SQLDataSources(environment, direction, dsn, dsn.length, &dsnLength, desc, desc.length, &descLength))) {
			if (ret == SQL_SUCCESS_WITH_INFO) {
				throw new DBIException("Data truncation occurred in the data source list.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
			direction = SQL_FETCH_NEXT;
			dataSourceList ~= dsn[0 .. dsnLength] ~ cast(SQLCHAR[])" ~ " ~ desc[0 .. descLength];
		}
		return cast(char[][])dataSourceList;
	}

	private:
	SQLHDBC connection;
	SQLHSTMT stmt;

	/**
	 * Get the last error message returned by the server.
	 *
	 * Returns:
	 *	The last error message returned by the server.
	 */
	char[] getLastErrorMessage () {
		SQLSMALLINT errorNumber;
		SQLCHAR[5] state;
		SQLINTEGER nativeCode;
		SQLCHAR[512] text;
		SQLSMALLINT textLength;

		SQLGetDiagField(SQL_HANDLE_DBC, connection, 0, SQL_DIAG_NUMBER, &errorNumber, 0, null);
		SQLGetDiagRec(SQL_HANDLE_DBC, connection, errorNumber, state, &nativeCode, text, text.length, &textLength);
		return cast(char[])state ~ " = " ~ cast(char[])text;
	}

	/**
	 * Get the last error code return by the server.  This is the native code.
	 *
	 * Returns:
	 *	The last error message returned by the server.
	 */
	int getLastErrorCode () {
		SQLSMALLINT errorNumber;
		SQLCHAR[5] state;
		SQLINTEGER nativeCode;
		SQLCHAR[512] text;
		SQLSMALLINT textLength;

		SQLGetDiagField(SQL_HANDLE_DBC, connection, 0, SQL_DIAG_NUMBER, &errorNumber, 0, null);
		SQLGetDiagRec(SQL_HANDLE_DBC, connection, errorNumber, state, &nativeCode, text, text.length, &textLength);
		return nativeCode;
	}
}