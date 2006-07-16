/**
 * Authors: The D DBI project
 *
 * Version: 0.2.2
 *
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteDatabase;

private import std.string;
private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.sqlite.imp, dbi.sqlite.SqliteError, dbi.sqlite.SqliteResult;

/**
 * An implementation of Database for use with SQLite databases.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class SqliteDatabase : Database {
	public:

	/**
	 * Create a new instance of SqliteDatabase, but don't open a database.
	 */
	this () {	
	}

	/**
	 * Create a new instance of SqliteDatabase and open a database.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] dbFile) {
		connect(dbFile);
	}

	/**
	 * Open a SQLite database for use.
	 *
	 * Params:
	 *	params = The name of the SQLite database to open.
	 *	username = Unused.
	 *	password = Unused.
	 *
	 * Throws:
	 *	DBIException if there was an error accessing the database.
	 *
	 * Examples:
	 *	---
	 *	SqliteDatabase db = new SqliteDatabase();
	 *	db.connect("_test.db", null, null);
	 *	---
	 */
	override void connect (char[] params, char[] username = null, char[] password = null) {
		if ((errorCode = sqlite3_open(params, &db)) != SQLITE_OK) {
			throw new DBIException("Could not open or create " ~ params, errorCode, specificToGeneral(errorCode));
		}
	}

	/**
	 * Close the current connection to the database.
	 */
	override void close () {
		sqlite3_close(db);
	}

	/**
	 * Execute a SQL statement that returns no results.
	 *
	 * Params:
	 *	sql = The SQL statement to _execute.
	 *
	 * Throws:
	 *	DBIException if the SQL code couldn't be executed.
	 */
	override void execute (char[] sql) {
		char** errorMessage;
		this.sql = sql;
		if ((errorCode = sqlite3_exec(db, sql, null, null, errorMessage)) != SQLITE_OK) {
			throw new DBIException(std.string.toString(sqlite3_errmsg(db)), sql, errorCode, specificToGeneral(errorCode));
		}
	}

	/**
	 * Query the database.
	 *
	 * Params:
	 *	sql = The SQL statement to execute.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 *
	 * Throws:
	 *	DBIException if the SQL code couldn't be executed.
	 */
	override Result query (char[] sql) {
		char** errorMessage;
		sqlite3_stmt* stmt;
		this.sql = sql;
		if ((errorCode = sqlite3_prepare(db, sql, sql.length, &stmt, errorMessage)) != SQLITE_OK) {
			throw new DBIException(std.string.toString(sqlite3_errmsg(db)), sql, errorCode, specificToGeneral(errorCode));
		}
		return new SqliteResult(stmt);
	}

	/**
	 * Get the error code.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.  This will be
	 *	removed in version 0.3.0.
	 *
	 * Returns:
	 *	The database specific error code.
	 */
	deprecated override int getErrorCode () {
		return sqlite3_errcode(db);
	}

	/**
	 * Get the error message.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.  This will be
	 *	removed in version 0.3.0.
	 *
	 * Returns:
	 *	The database specific error message.
	 */
	deprecated override char[] getErrorMessage () {
		return std.string.toString(sqlite3_errmsg(db));
	}

	/*
	 * Note: The following are not in the DBI API.
	 */

	/**
	 * Get the rowid of the last insert.
	 *
	 * Returns:
	 *	The row of the last insert or 0 if no inserts have been done.
	 */
	long getLastInsertRowId () {
		return sqlite3_last_insert_rowid(db);
	}

	/**
	 * Get the number of rows affected by the last SQL statement.
	 *
	 * Returns:
	 *	The number of rows affected by the last SQL statement.
	 */
	int getChanges () {
		return sqlite3_changes(db);
	}

	/**
	 * Get a list of all the table names.
	 *
	 * Returns: 
	 *	An array of all the table names.
	 */
	char[][] getTableNames () {
		return getItemNames("table");
	}

	/**
	 * Get a list of all the view names.
	 *
	 * Returns:
	 *	An array of all the view names.
	 */
	char[][] getViewNames () {
		return getItemNames("view");
	}

	/**
	 * Get a list of all the index names.
	 *
	 * Returns:
	 *	An array of all the index names.
	 */
	char[][] getIndexNames () {
		return getItemNames("index");
	}

	/**
	 * Check if a table exists.
	 *
	 * Param:
	 *	name = Name of the table to check for the existance of.
	 *
	 * Returns:
	 *	true if it exists or false otherwise.
	 */
	bool hasTable (char[] name) {
		return hasItem("table", name);
	}

	/**
	 * Check if a view exists.
	 *
	 * Params:
	 *	name = Name of the view to check for the existance of.
	 *
	 * Returns:
	 *	true if it exists or false otherwise.
	 */
	bool hasView (char[] name) {
		return hasItem("view", name);
	}

	/**
	 * Check if an index exists.
	 *
	 * Params:
	 *	name = Name of the index to check for the existance of.
	 *
	 * Returns:
	 *	true if it exists or false otherwise.
	 */
	bool hasIndex (char[] name) {
		return hasItem("index", name);
	}

	private:
	sqlite3* db;
	int errorCode;
	char[] sql;

	/**
	 *
	 */
	char[][] getItemNames(char[] type) {
		char[][] items;
		Row[] rows = queryFetchAll("SELECT name FROM sqlite_master WHERE type='" ~ type ~ "'");
		for (int idx = 0; idx < rows.length; idx++) {
			items ~= rows[idx].get(0);
		}
		return items;
	}

	/**
	 *
	 */
	bool hasItem(char[] type, char[] name) {
		Row[] rows = queryFetchAll("SELECT name FROM sqlite_master WHERE type='" ~ type ~ "' AND name='" ~ name ~ "'");
		if (rows !is null && rows.length > 0) {
			return true;
		}
		return false;
	}
}

unittest {
	void s1 (char[] s) {
		printf("%.*s\n", s);
	}
	void s2 (char[] s) {
		printf("   ...%.*s\n", s);
	}

	s1("dbi.sqlite.SqliteDatabase:");
	SqliteDatabase db = new SqliteDatabase();
	s2("connect");
	db.connect("_test.db");

	s2("query");
	Result res = db.query("SELECT * FROM people");
	assert(res != null);

	s2("fetchRow");
	Row row = res.fetchRow();
	assert(row != null);
	assert(row.getFieldIndex("name") == 1);
	assert(row.getFieldType(1) == SQLITE_TEXT);
	assert(row.getFieldDecl(1) == "char(40)");
	assert(row.get(0) == "1");
	assert(row.get("name") == "John Doe");
	assert(row["name"]     == "John Doe");
	assert(row.get(2) == "45");
	assert(row[2]     == "45");
	res.finish();

	s2("prepare");
	Statement stmt = db.prepare("SELECT * FROM people WHERE id = ?");
	stmt.bind(1, "1");
	res = stmt.query();
	row = res.fetchRow();
	res.finish();
	assert(row["id"] == "1");

	s2("fetchOne");
	row = db.queryFetchOne("SELECT * FROM people");
	assert(row["id"] == "1");

	s2("execute(INSERT)");
	db.execute("INSERT INTO people VALUES (0, 'Test Doe', '10')");
	s2("getChanges");
	assert(db.getChanges() == 1);

	s2("execute(DELETE via prepare statement)");
	stmt = db.prepare("DELETE FROM people WHERE id=?");
	stmt.bind(1, "0");
	stmt.execute();
	assert(db.getChanges() == 1);

	s2("getErrorCode, getErrorMessage");
	db.execute("SELECT * FROM doesnotexist");

	s2("getTableNames, getViewNames, getIndexNames");
	assert(db.getTableNames().length == 1);
	assert(db.getIndexNames().length == 0);
	assert(db.getViewNames( ).length == 0);

	s2("hasTable, hasView, hasIndex");
	assert(db.hasTable("people") == true);
	assert(db.hasTable("doesnotexist") == false);
	assert(db.hasIndex("doesnotexist") == false);
	assert(db.hasView( "doesnotexist") == false);

	db.close();
}