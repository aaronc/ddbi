/**
 * Authors: The D DBI project
 *
 * Copyright: BSD license
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
abstract class BaseResult : Result {
	/**
	 * A destructor that attempts to force the the release of of all
	 * statements handles and similar things.
	 *
	 * The current D garbage collector doesn't always call destructors,
	 * so it is HIGHLY recommended that you close connections manually.
	 */
	~this () {
		finish();
	}

	/**
	 * Throws:
	 *	DBIException if the function isn't overridden.
	 */
	override Row fetchRow () {
		throw new DBIException("Not implemented.");
	}

	/**
	 * Fetch all results returning an array of Row objects.
	 *
	 * Returns:
	 *	The retrieved rows.
	 */
	final override Row[] fetchAll () {
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
	override void finish () {
		throw new DBIException("Not implemented.");
	}
}