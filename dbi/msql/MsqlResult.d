/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.msql.MsqlResult;

version (dbi_msql) {


private import dbi.DBIException, dbi.Result, dbi.Row;
private import dbi.msql.imp;

/**
 * Manage a result set from a mSQL database query.
 *
 * See_Also:
 *	Result is the interface of which this provides an implementation.
 */
class MsqlResult : Result {
	public:
	this () {

	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
		return null;
	}

	/**
	 * Free all database resources used by a result set.
	 */
	override void finish () {

	}

	private:
}

}