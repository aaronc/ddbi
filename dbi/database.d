/**
 * Copyright: LGPL
 */
module dbi.Database;

private import dbi.Result, dbi.Row, dbi.Statement;

/**
 * Database interface that all DBD's must inherit from.
 */
interface Database {
	/**
	 * Connect to a database.
	 *
	 * Params:
	 *	conn = Connection string.
	 *	user = Username.  Defaults to null.
	 *	passwd = Password.  Defaults to null.
	 *
	 * Throws:
	 *	DBIException on error.
	 */
	void connect (char[] conn, char[] user, char[] passwd);

	/**
	 * Close the database connection.
	 *
	 * Throws:
	 *	DBIException on error.
	 */
	void close ();

	/**
	 * Execute a SQL statement that returns no results.
	 *
	 * Params:
	 *	sql = SQL statement to execute.
	 *
	 * Throws:
	 *	DBIException on error.
	 */
	void execute (char[] sql);

	/**
	 * Prepare a SQL statement for execution.
	 *
	 * Params:
	 *	sql = SQL statement to execute.
	 *
	 * Returns:
	 *	The prepared statements.
	 */
	Statement prepare (char[] sql);

	/**
	 * Query the database.
	 *
	 * Params:
	 *	sql = SQL statement to execute.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 */
	Result query (char[] sql);

	/**
	 * Query the database and return only the first row.
	 *
	 * Params:
	 *	sql = SQL statement to execute.
	 *
	 * Returns:
	 *	A Row object with the queried information.
	 */
	Row queryFetchOne (char[] sql);

	/**
	 * Query the database and return an array of all the rows.
	 *
	 * Params:
	 *	sql = SQL statement to execute
	 *
	 * Returns:
	 *	An array of Row objects with the queried information.
	 */
	Row[] queryFetchAll (char[] sql);

	/**
	 * Get the error code.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.
	 *
	 * Todo:
	 *	This function needs some thought. Should we wrap common SQL
	 *	errors into a "D DBI" error code so that ALL DBD's report the
	 *	same information? That's the way I am currently leaning. Any
	 *	input?
	 *
	 * Returns:
	 *	The database specific error code.
	 *
	 * See_Also:
	 *	getErrorMessage
	 */
	deprecated int getErrorCode ();

	/**
	 * Get the error message.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.
	 *
	 * Returns:
	 *	The database specific error code.
	 *
	 * See_Also:
	 *	getErrorCode
	 */
	deprecated char[] getErrorMessage ();
}