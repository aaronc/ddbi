/**
 * Copyright: LGPL
 */
module dbi.Result;

private import dbi.Row;

/**
 * Manage a result set from a database query.
 */
interface Result {
	/**
	 * Fetch one <Row> from the result set.
	 *
	 * Returns:
	 *	Null if the last row has already been fetched or a Row object otherwise.
	 */
	Row fetchRow ();

	/**
	 * Fetch all results into a Row array
	 *
	 * Returns:
	 *	An array of Row objects that can be empty.
	 */
	Row[] fetchAll ();

	/**
	 * Finish resultset. This should be called if you terminate a query
	 * without fetching all results.
	 */
	void finish ();
}