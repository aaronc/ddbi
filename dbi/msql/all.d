/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.msql.all;

version (build) {
	pragma (ignore);
}

version (dbi_msql) {

public import	dbi.msql.MsqlDatabase,
		dbi.msql.MsqlResult,
		dbi.all;

}