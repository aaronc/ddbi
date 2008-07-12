/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.all;

version (build) {
	pragma (ignore);
}

public import	dbi.Database,
		dbi.DBIException,
		dbi.ErrorCode,
		dbi.Registry;