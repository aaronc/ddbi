/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.mssql.all;

version (build) {
	pragma (ignore);
}

version (dbi_mssql) {

public import	dbi.mssql.MssqlDatabase,
		dbi.mssql.MssqlDate,
		dbi.mssql.MssqlResult,
		dbi.all;

}