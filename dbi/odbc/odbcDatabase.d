
/*######################################################################
##                                                                    ##
## ODBC integration for DDBI (odbcDatabase)                           ##
##	                                                                  ##
## This is effectively a DDBI wrapper for ODBC functionality.         ##
## Should work where there is a reasonable ODBC driver for a given    ##
## database.  Windows Only!  "odbcDatabase" is a misnomer but         ##
## follows the conventions of the DDBI project.                       ##
##                                                                    ##
## A huge special thanks to "David L" for making this possible        ##
## with his previous work on D headers for ODBC32.dll.  odbcDatabase  ##
## is dependant on his ODBC files within std.c.windows                ##
##                                  	                              ##
##		                        --- Mark Delano                       ##
##			                        (email@markdelano.com)    	      ##
##                                                                    ##
## 2006: MPSD                                                         ##
##                                  	                              ##
######################################################################*/

module dbi.odbc.odbcDatabase;

import std.string;
import dbi.BaseDatabase, dbi.Result, dbi.Row, dbi.Exception;
import dbi.odbc.imp, dbi.odbc.odbcResult;

// Thanks to David L, we go:
import std.c.windows.sql;
import std.c.windows.sqlext;
import std.c.windows.sqltypes;
import std.c.windows.odbc32dll;

class odbcDatabase : BaseDatabase {
	this() {
    	odbc_init(hODBC32DLL, henv, hdbc, hstmt);
    }

  int connect(char[] conn, char[] user=null, char[] passwd=null) {

	char[] host   = "localhost";
    char[] dbname = "test";
    char[] sock   = null;
    uint   port   = 0;
    
    if (conn.find("=") > 0) { // DSNLess
    
    	char[] buffer;
    	short   shtOutConnectStringLength = 0;
    	
    	buffer.length = 1024;    	
    	rc = odbcSQLDriverConnect(	hdbc, cast(HANDLE)0L, 
                           			std.string.toStringz(conn), cast(short)conn.length, 
                           			buffer,cast(short)  buffer.length, 
                           			&shtOutConnectStringLength, cast(ushort)SQL_DRIVER_COMPLETE);

    } else {
	    // DSN	    
     	dbname = conn;
    	rc = odbcSQLConnect( hdbc, dbname ~ "\0", SQL_NTS, "\0", SQL_NTS, "\0", SQL_NTS );
    }
    
    return rc;
  }

  int close() {
    odbc_close(hODBC32DLL, henv, hdbc);
    return 0;
    //return cast(int)odbc_errno();
  }

  int execute(char[] sql) {
	// writefln(sql);
	odbcSQLAllocHandle( SQL_HANDLE_STMT, hdbc, &hstmt );
	rc = odbcSQLExecDirect(hstmt, toStringz( sql ), SQL_NTS);
	
    if ( rc != SQL_SUCCESS ) {
        writefln( " SelectSQL failed! Exiting...", rc );
        odbcSQLFreeHandle(SQL_HANDLE_STMT, hstmt);
        return -1;
	}
	odbcSQLFreeHandle(SQL_HANDLE_STMT, hstmt);
	return 0;
  }

  Result query(char[] sql) {
	// writefln(sql);
	odbcSQLAllocHandle( SQL_HANDLE_STMT, hdbc, &hstmt );
	rc = odbcSQLExecDirect( hstmt, toStringz( sql ), SQL_NTS );
	odbcSQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_COMMIT);
	if (rc == SQL_SUCCESS) {
    	odbcResult res = new odbcResult(hstmt);	
    	// hstmt lives until res.finish()
    	return res;
	}
	else {
		writefln("SQLExecDirect failed: ", rc);
		odbcSQLFreeHandle(SQL_HANDLE_STMT, hstmt);
		return null;
	}
  }

  int getErrorCode() {
    return cast(int)odbc_errno();
  }

  char[] getErrorMessage() {
    return std.string.toString(odbc_error());
  }
  
  int odbc_store_result() { return 0; }

  private {

	int odbc_error() {
		return 0;
	}
	
	int odbc_errno() {
		return 0;
	}
	
	int odbc_close(HINSTANCE hODBC32DLL, HENV henv, HDBC hdbc) {

	    odbcSQLDisconnect( hdbc );
	    odbcSQLFreeHandle( SQL_HANDLE_DBC, hdbc );
	    odbcSQLFreeHandle( SQL_HANDLE_ENV, henv );
	    
	    FreeLibrary( hODBC32DLL );
	    
	    return 0;
	}	  
	  
    HENV    henv;
    HDBC    hdbc;
    HSTMT   hstmt;
    RETCODE rc;
  }
}