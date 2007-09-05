/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.ib.all;

version (build) {
	pragma (ignore);
}

version (dbi_ib) {

public import	dbi.ib.IbDatabase,
		dbi.ib.IbResult,
		dbi.all;
}