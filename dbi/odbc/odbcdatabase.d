/**
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.odbc.odbcDatabase;

// Almost every cast involving chars and SQLCHARs shouldn't exist, but involve bugs in
// WindowsAPI revision 144.  I'll see about fixing their ODBC and SQL files soon.
// WindowsAPI should also include odbc32.lib itself.

private import std.string;
private import dbi.BaseDatabase, dbi.DBIException, dbi.Result;
private import dbi.odbc.odbcResult;
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
 *
 */
class odbcDatabase : BaseDatabase {
	public:
	/**
	 *
	 */
	this () {
		if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_DBC, environment, &connection))) {
			throw new DBIException("Unable to create the ODBC connection.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
	}

	/**
	 *
	 */
	override void connect (char[] conn, char[] user = null, char[] passwd = null) {
		if (std.string.find(conn, "=") > 0) {
			SQLCHAR[1024] buffer;
			if (!SQL_SUCCEEDED(SQLDriverConnect(connection, null, cast(SQLCHAR*)conn, cast(SQLSMALLINT)conn.length, buffer, buffer.length, null, SQL_DRIVER_COMPLETE))) {
				throw new DBIException("Unable to connect to the database.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		} else {
			if (!SQL_SUCCEEDED(SQLConnect(connection, cast(SQLCHAR*)conn, cast(SQLSMALLINT)conn.length, cast(SQLCHAR*)user, cast(SQLSMALLINT)user.length, cast(SQLCHAR*)passwd, cast(SQLSMALLINT)passwd.length))) {
				throw new DBIException("Unable to connect to the database.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
			}
		}

	}

	/**
	 *
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
	 *
	 */
	override void execute (char[] sql) {
		if (!SQL_SUCCEEDED(SQLAllocHandle(SQL_HANDLE_STMT, connection, &stmt))) {
			throw new DBIException("Unable to create an ODBC statement.  ODBC returned " ~ getLastErrorMessage, getLastErrorCode);
		}
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
		if (!SQL_SUCCEEDED(SQLExecDirect(stmt, cast(SQLCHAR*)sql, sql.length))) {
			throw new DBIException("Unable to execute SQL code.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
		}
		
	}

	/**
	 *
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
			return new odbcResult(stmt);
		} else {
			throw new DBIException("Unable to query the database.  ODBC returned " ~ getLastErrorMessage, sql, getLastErrorCode);
		}
	}

	/**
	 *
	 */
	deprecated override int getErrorCode () {
		return getLastErrorCode;
	}

	/**
	 *
	 */
	deprecated override char[] getErrorMessage () {
		return getLastErrorMessage();
	}

	/*
	 * Note: The following are not in the DBI API.
	 */

	/**
	 * Get a list of ODBC drivers.
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