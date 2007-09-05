/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.odbc.all;

version (build) {
	pragma (ignore);
}


version (dbi_odbc) {

public import	dbi.odbc.OdbcDatabase,
		dbi.odbc.OdbcResult,
		dbi.all;

}