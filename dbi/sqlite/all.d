/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.sqlite.all;

version (build) {
	pragma (ignore);
}

version (dbi_sqlite) {

public import	dbi.sqlite.SqliteDatabase,
		dbi.sqlite.SqliteResult,
		dbi.all;

}