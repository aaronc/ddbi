/**
 * Authors: Mark Delano
 *
 * License: LGPL
 */

/*############################################
##                                          ##
## ODBC integration for DDBI (imp)          ##
##	                                    ##
## This code is pasted from or inspired by  ##
## David L.'s ODBC32 header conversion.     ##
##                                          ##
##                        MPSD, 2006        ##
##                                  	    ##
############################################*/


module dbi.odbc.imp;

private {
	import std.stdio, std.string;
}

import std.c.windows.windows, std.c.windows.sql, std.c.windows.sqlext, std.c.windows.sqltypes, std.c.windows.odbc32dll;


HINSTANCE hODBC32DLL = null;

pfn_SQLAllocConnect     odbcSQLAllocConnect; 
pfn_SQLAllocEnv         odbcSQLAllocEnv; 
pfn_SQLAllocHandle      odbcSQLAllocHandle;
pfn_SQLAllocStmt        odbcSQLAllocStmt; 
pfn_SQLBindCol          odbcSQLBindCol;
pfn_SQLBindParam        odbcSQLBindParam;
pfn_SQLBindParameter    odbcSQLBindParameter;
pfn_SQLBrowseConnect    odbcSQLBrowseConnect;
pfn_SQLBulkOperations   odbcSQLBulkOperations;
pfn_SQLCancel           odbcSQLCancel;    
pfn_SQLCloseCursor      odbcSQLCloseCursor;    
pfn_SQLColAttribute     odbcSQLColAttribute;
pfn_SQLColAttributes    odbcSQLColAttributes;
pfn_SQLColumnPrivileges odbcSQLColumnPrivileges;
pfn_SQLColumns          odbcSQLColumns; 
pfn_SQLConnect          odbcSQLConnect; 
pfn_SQLCopyDesc         odbcSQLCopyDesc; 
pfn_SQLDataSources      odbcSQLDataSources; 
pfn_SQLDescribeCol      odbcSQLDescribeCol;
pfn_SQLDescribeParam    odbcSQLDescribeParam;
pfn_SQLDisconnect       odbcSQLDisconnect; 
pfn_SQLDriverConnect    odbcSQLDriverConnect; 
pfn_SQLDrivers          odbcSQLDrivers;
pfn_SQLEndTran          odbcSQLEndTran;
pfn_SQLError            odbcSQLError;
pfn_SQLExecDirect       odbcSQLExecDirect;
pfn_SQLExecute          odbcSQLExecute;
pfn_SQLExtendedFetch    odbcSQLExtendedFetch;
pfn_SQLFetch            odbcSQLFetch;
pfn_SQLFetchScroll      odbcSQLFetchScroll;
pfn_SQLForeignKeys      odbcSQLForeignKeys;
pfn_SQLFreeConnect      odbcSQLFreeConnect; 
pfn_SQLFreeEnv          odbcSQLFreeEnv; 
pfn_SQLFreeHandle       odbcSQLFreeHandle;
pfn_SQLFreeStmt         odbcSQLFreeStmt;
pfn_SQLGetConnectAttr   odbcSQLGetConnectAttr;
pfn_SQLGetConnectOption odbcSQLGetConnectOption;
pfn_SQLGetCursorName    odbcSQLGetCursorName;
pfn_SQLGetData          odbcSQLGetData;
pfn_SQLGetDescField     odbcSQLGetDescField;
pfn_SQLGetDescRec       odbcSQLGetDescRec;
pfn_SQLGetDiagField     odbcSQLGetDiagField;
pfn_SQLGetDiagRec       odbcSQLGetDiagRec;
pfn_SQLGetEnvAttr       odbcSQLGetEnvAttr;
pfn_SQLGetFunctions     odbcSQLGetFunctions;
pfn_SQLGetStmtAttr      odbcSQLGetStmtAttr;
pfn_SQLGetStmtOption    odbcSQLGetStmtOption;
pfn_SQLGetTypeInfo      odbcSQLGetTypeInfo;
pfn_SQLMoreResults      odbcSQLMoreResults;
pfn_SQLNativeSql        odbcSQLNativeSql;
pfn_SQLNumParams        odbcSQLNumParams;
pfn_SQLNumResultCols    odbcSQLNumResultCols;
pfn_SQLParamData        odbcSQLParamData;
pfn_SQLParamOptions     odbcSQLParamOptions;
pfn_SQLPrepare          odbcSQLPrepare;
pfn_SQLPrimaryKeys      odbcSQLPrimaryKeys;
pfn_SQLProcedureColumns odbcSQLProcedureColumns;
pfn_SQLProcedures       odbcSQLProcedures;
pfn_SQLPutData          odbcSQLPutData;
pfn_SQLRowCount         odbcSQLRowCount;
pfn_SQLSetConnectAttr   odbcSQLSetConnectAttr;
pfn_SQLSetConnectOption odbcSQLSetConnectOption;
pfn_SQLSetCursorName    odbcSQLSetCursorName;
pfn_SQLSetDescField     odbcSQLSetDescField;
pfn_SQLSetDescRec       odbcSQLSetDescRec;
pfn_SQLSetEnvAttr       odbcSQLSetEnvAttr;
pfn_SQLSetParam         odbcSQLSetParam;
pfn_SQLSetPos           odbcSQLSetPos;
pfn_SQLSetStmtAttr      odbcSQLSetStmtAttr;
pfn_SQLSetStmtOption    odbcSQLSetStmtOption;
pfn_SQLSpecialColumns   odbcSQLSpecialColumns;
pfn_SQLStatistics       odbcSQLStatistics;
pfn_SQLTablePrivileges  odbcSQLTablePrivileges;
pfn_SQLTables           odbcSQLTables;
pfn_SQLTransact         odbcSQLTransact;    
    
	void odbc_init(HINSTANCE hODBC32DLL, inout HENV henv, inout HDBC hdbc, inout HSTMT hstmt) {
	
	    char[]    sLibName   = r"C:\windows\system32\odbc32.dll";
	    hODBC32DLL = LoadLibraryA( std.string.toStringz( sLibName ) );
	    
	    // writef("Library ", sLibName, " loaded, ODBC32.DLL handle=%d", cast(int)hODBC32DLL );
	    
	    if ( hODBC32DLL <= cast(HINSTANCE)0 )
	    {
	        printf( r"C:\windows\system32\odbc32.dll not found!" );
	        hODBC32DLL = null;
	
	        assert(0);
	    } 	    

	    odbcSQLAllocConnect     = cast(pfn_SQLAllocConnect)GetProcAddress( hODBC32DLL, "SQLAllocConnect" ); 
	    odbcSQLAllocEnv         = cast(pfn_SQLAllocEnv)GetProcAddress( hODBC32DLL, "SQLAllocEnv" ); 
	    odbcSQLAllocHandle      = cast(pfn_SQLAllocHandle)GetProcAddress( hODBC32DLL, "SQLAllocHandle" );
	    odbcSQLAllocStmt        = cast(pfn_SQLAllocStmt)GetProcAddress( hODBC32DLL, "SQLAllocStmt" ); 
	    odbcSQLBindCol          = cast(pfn_SQLBindCol)GetProcAddress( hODBC32DLL, "SQLBindCol" );
	    odbcSQLBindParam        = cast(pfn_SQLBindParam)GetProcAddress( hODBC32DLL, "SQLBindParam" );
	    odbcSQLBindParameter    = cast(pfn_SQLBindParameter)GetProcAddress( hODBC32DLL, "SQLBindParameter" );
	    odbcSQLBrowseConnect    = cast(pfn_SQLBrowseConnect)GetProcAddress( hODBC32DLL, "SQLBrowseConnect" );
	    odbcSQLBulkOperations   = cast(pfn_SQLBulkOperations)GetProcAddress( hODBC32DLL, "SQLBulkOperations" );
	    odbcSQLCancel           = cast(pfn_SQLCancel)GetProcAddress( hODBC32DLL, "SQLCancel" );    
	    odbcSQLCloseCursor      = cast(pfn_SQLCloseCursor)GetProcAddress( hODBC32DLL, "SQLCloseCursor" );    
	    odbcSQLColAttribute     = cast(pfn_SQLColAttribute)GetProcAddress( hODBC32DLL, "SQLColAttribute" );
	    odbcSQLColAttributes    = cast(pfn_SQLColAttributes)GetProcAddress( hODBC32DLL, "SQLColAttributes" );
	    odbcSQLColumnPrivileges = cast(pfn_SQLColumnPrivileges)GetProcAddress( hODBC32DLL, "SQLColumnPrivileges" );
	    odbcSQLColumns          = cast(pfn_SQLColumns)GetProcAddress( hODBC32DLL, "SQLColumns" ); 
	    odbcSQLConnect          = cast(pfn_SQLConnect)GetProcAddress( hODBC32DLL, "SQLConnect" ); 
	    odbcSQLCopyDesc         = cast(pfn_SQLCopyDesc)GetProcAddress( hODBC32DLL, "SQLCopyDesc" ); 
	    odbcSQLDataSources      = cast(pfn_SQLDataSources)GetProcAddress( hODBC32DLL, "SQLDataSources" ); 
	    odbcSQLDescribeCol      = cast(pfn_SQLDescribeCol)GetProcAddress( hODBC32DLL, "SQLDescribeCol" );
	    odbcSQLDescribeParam    = cast(pfn_SQLDescribeParam)GetProcAddress( hODBC32DLL, "SQLDescribeParam" );
	    odbcSQLDisconnect       = cast(pfn_SQLDisconnect)GetProcAddress( hODBC32DLL, "SQLDisconnect" ); 
	    odbcSQLDriverConnect    = cast(pfn_SQLDriverConnect)GetProcAddress( hODBC32DLL, "SQLDriverConnect" ); 
	    odbcSQLDrivers          = cast(pfn_SQLDrivers)GetProcAddress( hODBC32DLL, "SQLDrivers" );
	    odbcSQLEndTran          = cast(pfn_SQLEndTran)GetProcAddress( hODBC32DLL, "SQLEndTran" );
	    odbcSQLError            = cast(pfn_SQLError)GetProcAddress( hODBC32DLL, "SQLError" );
	    odbcSQLExecDirect       = cast(pfn_SQLExecDirect)GetProcAddress( hODBC32DLL, "SQLExecDirect" );
	    odbcSQLExecute          = cast(pfn_SQLExecute)GetProcAddress( hODBC32DLL, "SQLExecute" );
	    odbcSQLExtendedFetch    = cast(pfn_SQLExtendedFetch)GetProcAddress( hODBC32DLL, "SQLExtendedFetch" );
	    odbcSQLFetch            = cast(pfn_SQLFetch)GetProcAddress( hODBC32DLL, "SQLFetch" );
	    odbcSQLFetchScroll      = cast(pfn_SQLFetchScroll)GetProcAddress( hODBC32DLL, "SQLFetchScroll" );
	    odbcSQLForeignKeys      = cast(pfn_SQLForeignKeys)GetProcAddress( hODBC32DLL, "SQLForeignKeys" );
	    odbcSQLFreeConnect      = cast(pfn_SQLFreeConnect)GetProcAddress( hODBC32DLL, "SQLFreeConnect" ); 
	    odbcSQLFreeEnv          = cast(pfn_SQLFreeEnv)GetProcAddress( hODBC32DLL, "SQLFreeEnv" ); 
	    odbcSQLFreeHandle       = cast(pfn_SQLFreeHandle)GetProcAddress( hODBC32DLL, "SQLFreeHandle" );
	    odbcSQLFreeStmt         = cast(pfn_SQLFreeStmt)GetProcAddress( hODBC32DLL, "SQLFreeStmt" );
	    odbcSQLGetConnectAttr   = cast(pfn_SQLGetConnectAttr)GetProcAddress( hODBC32DLL, "SQLGetConnectAttr" );
	    odbcSQLGetConnectOption = cast(pfn_SQLGetConnectOption)GetProcAddress( hODBC32DLL, "SQLGetConnectOption" );
	    odbcSQLGetCursorName    = cast(pfn_SQLGetCursorName)GetProcAddress( hODBC32DLL, "SQLGetCursorName" );
	    odbcSQLGetData          = cast(pfn_SQLGetData)GetProcAddress( hODBC32DLL, "SQLGetData" );
	    odbcSQLGetDescField     = cast(pfn_SQLGetDescField)GetProcAddress( hODBC32DLL, "SQLGetDescField" );
	    odbcSQLGetDescRec       = cast(pfn_SQLGetDescRec)GetProcAddress( hODBC32DLL, "SQLGetDescRec" );
	    odbcSQLGetDiagField     = cast(pfn_SQLGetDiagField)GetProcAddress( hODBC32DLL, "SQLGetDiagField" );
	    odbcSQLGetDiagRec       = cast(pfn_SQLGetDiagRec)GetProcAddress( hODBC32DLL, "SQLGetDiagRec" );
	    odbcSQLGetEnvAttr       = cast(pfn_SQLGetEnvAttr)GetProcAddress( hODBC32DLL, "SQLGetEnvAttr" );
	    odbcSQLGetFunctions     = cast(pfn_SQLGetFunctions)GetProcAddress( hODBC32DLL, "SQLGetFunctions" );
	    odbcSQLGetStmtAttr      = cast(pfn_SQLGetStmtAttr)GetProcAddress( hODBC32DLL, "SQLGetStmtAttr" );
	    odbcSQLGetStmtOption    = cast(pfn_SQLGetStmtOption)GetProcAddress( hODBC32DLL, "SQLGetStmtOption" );
	    odbcSQLGetTypeInfo      = cast(pfn_SQLGetTypeInfo)GetProcAddress( hODBC32DLL, "SQLGetTypeInfo" );
	    odbcSQLMoreResults      = cast(pfn_SQLMoreResults)GetProcAddress( hODBC32DLL, "SQLMoreResults" );
	    odbcSQLNativeSql        = cast(pfn_SQLNativeSql)GetProcAddress( hODBC32DLL, "SQLNativeSql" );
	    odbcSQLNumParams        = cast(pfn_SQLNumParams)GetProcAddress( hODBC32DLL, "SQLNumParams" );
	    odbcSQLNumResultCols    = cast(pfn_SQLNumResultCols)GetProcAddress( hODBC32DLL, "SQLNumResultCols" );
	    odbcSQLParamData        = cast(pfn_SQLParamData)GetProcAddress( hODBC32DLL, "SQLParamData" );
	    odbcSQLParamOptions     = cast(pfn_SQLParamOptions)GetProcAddress( hODBC32DLL, "SQLParamOptions" );
	    odbcSQLPrepare          = cast(pfn_SQLPrepare)GetProcAddress( hODBC32DLL, "SQLPrepare" );
	    odbcSQLPrimaryKeys      = cast(pfn_SQLPrimaryKeys)GetProcAddress( hODBC32DLL, "SQLPrimaryKeys" );
	    odbcSQLProcedureColumns = cast(pfn_SQLProcedureColumns)GetProcAddress( hODBC32DLL, "SQLProcedureColumns" );
	    odbcSQLProcedures       = cast(pfn_SQLProcedures)GetProcAddress( hODBC32DLL, "SQLProcedures" );
	    odbcSQLPutData          = cast(pfn_SQLPutData)GetProcAddress( hODBC32DLL, "SQLPutData" );
	    odbcSQLRowCount         = cast(pfn_SQLRowCount)GetProcAddress( hODBC32DLL, "SQLRowCount" );
	    odbcSQLSetConnectAttr   = cast(pfn_SQLSetConnectAttr)GetProcAddress( hODBC32DLL, "SQLSetConnectAttr" );
	    odbcSQLSetConnectOption = cast(pfn_SQLSetConnectOption)GetProcAddress( hODBC32DLL, "SQLSetConnectOption" );
	    odbcSQLSetCursorName    = cast(pfn_SQLSetCursorName)GetProcAddress( hODBC32DLL, "SQLSetCursorName" );
	    odbcSQLSetDescField     = cast(pfn_SQLSetDescField)GetProcAddress( hODBC32DLL, "SQLSetDescField" );
	    odbcSQLSetDescRec       = cast(pfn_SQLSetDescRec)GetProcAddress( hODBC32DLL, "SQLSetDescRec" );
	    odbcSQLSetEnvAttr       = cast(pfn_SQLSetEnvAttr)GetProcAddress( hODBC32DLL, "SQLSetEnvAttr" );
	    odbcSQLSetParam         = cast(pfn_SQLSetParam)GetProcAddress( hODBC32DLL, "SQLSetParam" );
	    odbcSQLSetPos           = cast(pfn_SQLSetPos)GetProcAddress( hODBC32DLL, "SQLSetPos" );
	    odbcSQLSetStmtAttr      = cast(pfn_SQLSetStmtAttr)GetProcAddress( hODBC32DLL, "SQLSetStmtAttr" );
	    odbcSQLSetStmtOption    = cast(pfn_SQLSetStmtOption)GetProcAddress( hODBC32DLL, "SQLSetStmtOption" );
	    odbcSQLSpecialColumns   = cast(pfn_SQLSpecialColumns)GetProcAddress( hODBC32DLL, "SQLSpecialColumns" );
	    odbcSQLStatistics       = cast(pfn_SQLStatistics)GetProcAddress( hODBC32DLL, "SQLStatistics" );
	    odbcSQLTablePrivileges  = cast(pfn_SQLTablePrivileges)GetProcAddress( hODBC32DLL, "SQLTablePrivileges" );
	    odbcSQLTables           = cast(pfn_SQLTables)GetProcAddress( hODBC32DLL, "SQLTables" );
	    odbcSQLTransact         = cast(pfn_SQLTransact)GetProcAddress( hODBC32DLL, "SQLTransact" );

		
	    odbcSQLAllocHandle( SQL_HANDLE_ENV, SQL_NULL_HANDLE, &henv );
	    
	    //Set the Environment to ODBC v3.0
	    odbcSQLSetEnvAttr( henv, SQL_ATTR_ODBC_VERSION, cast(void *)SQL_OV_ODBC3, 0 );
	    
	    odbcSQLAllocHandle( SQL_HANDLE_DBC, henv, &hdbc );	    	    
	}
