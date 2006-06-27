/**
 * Copyright: LGPL
 */
module dbi.odbc.odbcDatabase;

private import std.string;
private import dbi.BaseDatabase, dbi.DBIException, dbi.Result;
private import dbi.odbc.imp, dbi.odbc.odbcResult;

/**
 *
 */
class odbcDatabase : BaseDatabase {
	/**
	 *
	 */
	this () {
		odbc_init(hODBC32DLL, henv, hdbc, hstmt);
	}

	/**
	 *
	 */
	void connect (char[] conn, char[] user=null, char[] passwd=null) {
		char[] host = "localhost";
		char[] dbname = "test";
		char[] sock = null;
		uint port = 0;
		if (conn.find("=") > 0) { // DSNLess
			char[] buffer;
			short shtOutConnectStringLength = 0;
			buffer.length = 1024;    	
			rc = odbcSQLDriverConnect(hdbc, cast(HANDLE)0L, std.string.toStringz(conn), cast(short)conn.length, buffer, cast(short)buffer.length, &shtOutConnectStringLength, cast(ushort)SQL_DRIVER_COMPLETE);
		} else { // DSN	    
			dbname = conn;
			rc = odbcSQLConnect(hdbc, dbname ~ "\0", SQL_NTS, "\0", SQL_NTS, "\0", SQL_NTS);
		}
		//return rc;
	}

	/**
	 *
	 */
	void close () {
		odbc_close(hODBC32DLL, henv, hdbc);
		//return odbc_errno();
	}

	/**
	 *
	 */
	void execute (char[] sql) {
		odbcSQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
		rc = odbcSQLExecDirect(hstmt, toStringz(sql), SQL_NTS);
		if (rc != SQL_SUCCESS) {
			odbcSQLFreeHandle(SQL_HANDLE_STMT, hstmt);
			throw new DBIException("SelectSQL failed! Exiting...", rc);
		}
		odbcSQLFreeHandle(SQL_HANDLE_STMT, hstmt);
		//return 0;
	}

	/**
	 *
	 */
	Result query (char[] sql) {
		odbcSQLAllocHandle( SQL_HANDLE_STMT, hdbc, &hstmt );
		rc = odbcSQLExecDirect( hstmt, toStringz( sql ), SQL_NTS );
		odbcSQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
		if (rc == SQL_SUCCESS) {
			odbcResult res = new odbcResult(hstmt);	// hstmt lives until res.finish()
			return res;
		} else {
			odbcSQLFreeHandle(SQL_HANDLE_STMT, hstmt);
			throw new DBIException("SQLExecDirect failed: ", rc);
		}
	}

	/**
	 *
	 */
	deprecated int getErrorCode () {
		return cast(int)odbc_errno();
	}

	/**
	 *
	 */
	deprecated char[] getErrorMessage () {
		return std.string.toString(odbc_error());
	}

	/**
	 *
	 */
	int odbc_store_result () {
		return 0;
	}

	private:
	HENV henv;
	HDBC hdbc;
	HSTMT hstmt;
	RETCODE rc;

	/**
	 *
	 */
	int odbc_error () {
		return 0;
	}

	/**
	 *
	 */
	int odbc_errno () {
		return 0;
	}

	/**
	 *
	 */
	int odbc_close (HINSTANCE hODBC32DLL, HENV henv, HDBC hdbc) {
		odbcSQLDisconnect(hdbc);
		odbcSQLFreeHandle(SQL_HANDLE_DBC, hdbc);
		odbcSQLFreeHandle(SQL_HANDLE_ENV, henv);
		FreeLibrary(hODBC32DLL);
		return 0;
	}
}