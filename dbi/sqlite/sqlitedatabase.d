/**
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteDatabase;

private import std.string;
private import dbi.BaseDatabase, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.sqlite.imp, dbi.sqlite.SqliteResult;

/**
 * Manage a SQLite database. This class implements all of the current
 * DBD interface as defined in Database. In addition, a few "extra"
 * functions are included.
 *
 * See_Also:
 *	BaseDatabase, Database
 */
class SqliteDatabase : BaseDatabase {
	public:

	/**
	 *
	 */
	this () {	
	}

	/**
	 *
	 */
	this (char[] dbFile) {
		if ((errorCode = sqlite3_open(dbFile, &db)) != SQLITE_OK) {
			throw new DBIException("Could not open or create: " ~ dbFile, errorCode);
		}
	}

	/**
	 * Connect to a database or create one if necessary.
	 *
	 * Params:
	 *	dbFile - Database filename to open or create.
	 *	user - Unused.
	 *	passwd - Unused.
	 */
	override void connect (char[] dbFile, char[] user = null, char[] passwd = null) {
		if ((errorCode = sqlite3_open(dbFile, &db)) != SQLITE_OK) {
			throw new DBIException("Could not open or create: " ~ dbFile, errorCode);
		}
	}

	/**
	 *
	 */
	override void close () {
		sqlite3_close(db);
	}

	/**
	 *
	 */
	override void execute (char[] sql) {
		char** errorMessage;
		this.sql = sql;
		if ((errorCode = sqlite3_exec(db, sql, null, null, errorMessage)) != SQLITE_OK) {
			throw new DBIException(std.string.toString(sqlite3_errmsg(db)), sql, errorCode);
		}
	}

	/**
	 *
	 */
	override Result query (char[] sql) {
		char** errorMessage;
		sqlite3_stmt* stmt;
		this.sql = sql;
		if ((errorCode = sqlite3_prepare(db, sql, sql.length, &stmt, errorMessage)) != SQLITE_OK) {
			throw new DBIException(std.string.toString(sqlite3_errmsg(db)), sql, errorCode);
		}
		return new SqliteResult(stmt);
	}

	/**
	 *
	 */
	deprecated override int getErrorCode () {
		return sqlite3_errcode(db);
	}

	/**
	 *
	 */
	deprecated override char[] getErrorMessage () {
		return std.string.toString(sqlite3_errmsg(db));
	}

	/*
	 * Note: The following are not in the DBI API.
	 */

	/**
	 *
	 */
	long getLastInsertRowId () {
		return sqlite3_last_insert_rowid(db);
	}

	/**
	 *
	 */
	int getChanges () {
		return sqlite3_changes(db);
	}

	/**
	 * Get a list of all table names.
	 *
	 * Returns: 
	 *	Array of all table names.
	 */
	char[][] getTableNames () {
		return getItemNames("table");
	}

	/**
	 * Get a list of all view names.
	 *
	 * Returns:
	 *	Array of all view names.
	 */
	char[][] getViewNames () {
		return getItemNames("view");
	}

	/**
	 * Get a list of all index names.
	 *
	 * Returns:
	 *	Array of all index names.
	 */
	char[][] getIndexNames () {
		return getItemNames("index");
	}

	/**
	 * Does this database have the given table?
	 *
	 * Param:
	 *	name = Name of the table to check for the existance of.
	 *
	 * Returns:
	 *	false if it doesn't have it and true otherwise.
	 */
	bool hasTable (char[] name) {
		return hasItem("table", name);
	}

	/**
	 * Does this database have the given view?
	 *
	 * Params:
	 *	name = Name of the view to check for the existance of.
	 *
	 * Returns:
	 *	false if it doesn't have it and true otherwise.
	 */
	bool hasView (char[] name) {
		return hasItem("view", name);
	}

	/**
	 * Does this database have the given index?
	 *
	 * Params:
	 *	name = Name of the index to check for the existance of.
	 *
	 * Returns:
	 *	false if it doesn't have it and true otherwise.
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
		for (int idx=0; idx < rows.length; idx++) {
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