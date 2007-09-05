/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.oracle.all;

version (build) {
	pragma (ignore);
}

version (dbi_oracle) {

public import	dbi.oracle.OracleDatabase,
		dbi.oracle.OracleResult,
		dbi.all;

}