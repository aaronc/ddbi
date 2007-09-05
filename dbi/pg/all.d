/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.pg.all;

version (build) {
	pragma (ignore);
}

version (dbi_pg) {

	public import	dbi.pg.PgDatabase,
		dbi.pg.PgResult,
		dbi.all;
	
}