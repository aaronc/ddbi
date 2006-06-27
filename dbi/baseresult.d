/**
 * Copyright: LGPL
 */
module dbi.BaseResult;

private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row;

/**
 * All DBI Result classes should inherit from BaseResult instead
 * of Result directly. This class will provide a default
 * implementation of fetchAll() which seems to work on all DBI
 * drivers.
 *
 * See_Also:
 *	Result
 */
class BaseResult : Result {
	/**
	 * Throws:
	 *	DBIException if the function isn't overridden.
	 */
	Row fetchRow () {
		throw new DBIException("Not implemented.");
	}

	/**
	 * Fetch all results returning an array of Row objects.
	 *
	 * Returns:
	 *	The retrieved rows.
	 */
	Row[] fetchAll () {
		Row[] rows;
		Row row;
		while ((row = fetchRow()) !is null) {
			rows ~= row;
		}
		finish();
		return rows;
	}

	/**
	 * Throws:
	 *	DBIException if the function isn't overridden.
	 */
	void finish () {
		throw new DBIException("Not implemented.");
	}
}