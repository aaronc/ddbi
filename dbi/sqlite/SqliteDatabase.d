/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteDatabase;

version = dbi_sqlite;
version (dbi_sqlite) {


private import tango.stdc.stringz : toDString = fromStringz, toCString = toStringz;
private import tango.util.log.Log;
    
public import dbi.Database;
import dbi.DBIException, dbi.Statement, dbi.Registry, dbi.Statement;
import dbi.sqlite.imp, dbi.sqlite.SqliteError;

import dbi.sqlite.SqliteStatement; 

import Integer = tango.text.convert.Integer;

/**
 * An implementation of Database for use with SQLite databases.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class SqliteDatabase : Database {
	
	private Logger logger;
	public:

	/**
	 * Create a new instance of SqliteDatabase, but don't open a database.
	 */
	this () {
		logger = Log.getLogger("dbi.sqlite.Database");
	}

	/**
	 * Create a new instance of SqliteDatabase and open a database.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] dbFile) {
		logger = Log.getLogger("dbi.sqlite.Database");
		connect(dbFile);
	}

	/**
	 * Open a SQLite database for use.
	 *
	 * Params:
	 *	dbfile = The name of the SQLite database to open.
	 *
	 * Throws:
	 *	DBIException if there was an error accessing the database.
	 *
	 * Examples:
	 *	---
	 *	SqliteDatabase db = new SqliteDatabase();
	 *	db.connect("_test.db");
	 *	---
	 */
	void connect (char[] dbfile) {
		logger.trace("connecting: " ~ dbfile);
		if ((errorCode = sqlite3_open(toCString(dbfile), &database)) != SQLITE_OK) {
			throw new DBIException("Could not open or create " ~ dbfile, errorCode, specificToGeneral(errorCode));
		}
	}

	/**
	 * Close the current connection to the database.
	 */
	override void close () {
		logger.trace("closing database now");
		if (database !is null) {
			while(lastSt) {
				lastSt.close;
				lastSt = lastSt.lastSt;
			}
			
			if ((errorCode = sqlite3_close(database)) != SQLITE_OK) {
				throw new DBIException(toDString(sqlite3_errmsg(database)), errorCode, specificToGeneral(errorCode));
			}
			database = null;
		}
	}
	
	IStatement prepare(char[] sql)
	{
		logger.trace("querying: " ~ sql);
		char** errorMessage;
		sqlite3_stmt* stmt;
		if ((errorCode = sqlite3_prepare_v2(database, toCString(sql), sql.length, &stmt, errorMessage)) != SQLITE_OK) {
			throw new DBIException("sqlite3_prepare_v2 error: " ~ toDString(sqlite3_errmsg(database)), sql, errorCode, specificToGeneral(errorCode));
		}
		
		lastSt = new SqliteStatement(database, stmt, sql, lastSt);
		return lastSt;
	}
	
	private SqliteStatement lastSt = null;
			
	IStatement virtualPrepare(char[] sql) { return prepare(sql); }

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
		logger.trace("executing: " ~ sql);
		char** errorMessage;
		if ((errorCode = sqlite3_exec(database, sql.dup.ptr, null, null, errorMessage)) != SQLITE_OK) {
			throw new DBIException(toDString(sqlite3_errmsg(database)), sql, errorCode, specificToGeneral(errorCode));
		}
	}
	
	void execute(char[] sql, BindType[] bindTypes, void*[] ptrs)
	{
		logger.trace("querying: " ~ sql);
		char** errorMessage;
		sqlite3_stmt* stmt;
		if ((errorCode = sqlite3_prepare_v2(database, toCString(sql), sql.length, &stmt, errorMessage)) != SQLITE_OK) {
			throw new DBIException(toDString(sqlite3_errmsg(database)), sql, errorCode, specificToGeneral(errorCode));
		}
		
		auto len = bindTypes.length;
		if(ptrs.length != len) throw new DBIException;
		
		for(size_t i = 0; i < len; ++i)
		{
			SqliteStatement.bind!(true)(stmt, bindTypes[i], ptrs[i], i);
		}
		
		auto res = sqlite3_step(stmt);
		if(res != SQLITE_ROW || res != SQLITE_DONE)
			throw new DBIException;
		
		sqlite3_finalize(stmt);
	}

	/*
	 * Note: The following are not in the DBI API.
	 */


	/**
	 * Get the number of rows affected by the last SQL statement.
	 *
	 * Returns:
	 *	The number of rows affected by the last SQL statement.
	 */
	int getChanges () {
		return sqlite3_changes(database);
	}

/+	/**
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
	}+/
	
	void beginTransact() {}
	void rollback() {}
	void commit() {}
	
	debug(DBITest) {
		override void doTests()
		{
			auto test = new SqliteTest(this);
			test.run;
		}
	}

	private:
	sqlite3* database;
//	bool isOpen = false;
	int errorCode;

/+	/**
	 *
	 */
	char[][] getItemNames(char[] type) {
		char[][] items;
		Row[] rows = queryFetchAll("SELECT name FROM sqlite_master WHERE type='" ~ type ~ "'");
		for (size_t i = 0; i < rows.length; i++) {
			items ~= rows[i].get(0);
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
	}+/
}

private class SqliteRegister : Registerable {
	
	private Logger logger;
	
	this() {
		logger = Log.getLogger("dbi.sqlite");
	}
	
	public char[] getPrefix() {
		return "sqlite";
	}
	
	public Database getInstance(char[] url) {
		logger.trace("creating Sqlite database: " ~ url);
		return new SqliteDatabase(url);
	}
}

debug(DBITest) {
	
	class SqliteTest : DBTest
	{
		this(Database db, bool virtual = false)
		{
			super(db, virtual);
		}
		
		void setup()
		{
			char[] drop_test = `DROP TABLE IF EXISTS "dbi_test"`;
			
			Stdout.formatln("executing: {}", drop_test);
			
			db.execute(drop_test);
			
			char[] create_test = `CREATE TABLE  "dbi_test" ( `
				`"id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, `
				`"name" TEXT NOT NULL, `
				`"binary" BLOB DEFAULT  NULL, `
				`"dateofbirth" TEXT DEFAULT NULL`
			`)`;
			
			Stdout.formatln("executing: {}", create_test);
			
			db.execute(create_test);
		}
		
		void teardown()
		{
			
		}
	}
	
unittest {
    void s1 (char[] s) {
        tango.io.Stdout.Stdout(s).newline();
    }

    void s2 (char[] s) {
        tango.io.Stdout.Stdout("   ..." ~ s).newline();
    }

	s1("dbi.sqlite.SqliteDatabase:");
	SqliteDatabase db = new SqliteDatabase();
	s2("connect");
	db.connect("test.db");

	s2("query");

	db.test;
	
/+	Result res = db.query("SELECT * FROM test");
	assert (res !is null);

	s2("fetchRow");
	Row row = res.fetchRow();
	assert (row !is null);
	assert (row.getFieldIndex("id") == 0);
	assert (row.getFieldIndex("name") == 1);
	assert (row.getFieldIndex("dateofbirth") == 2);
	assert (row.get("id") == "1");
	assert (row.get("name") == "John Doe");
	assert (row.get("dateofbirth") == "1970-01-01");
	assert (row.getFieldType(1) == SQLITE_TEXT);
	assert (row.getFieldDecl(1) == "char(40)");
	res.finish();

	s2("prepare");
	Statement stmt = db.prepare("SELECT * FROM test WHERE id = ?");
	stmt.bind(1, "1");
	res = stmt.query();
	row = res.fetchRow();
	res.finish();
	assert (row[0] == "1");

	s2("fetchOne");
	row = db.queryFetchOne("SELECT * FROM test");
	assert (row[0] == "1");

	s2("execute(INSERT)");
	db.execute("INSERT INTO test VALUES (2, 'Jane Doe', '2000-12-31')");

	s2("execute(DELETE via prepare statement)");
	stmt = db.prepare("DELETE FROM test WHERE id=?");
	stmt.bind(1, "2");
	stmt.execute();

	s2("getChanges");
	assert (db.getChanges() == 1);

	s2("getTableNames, getViewNames, getIndexNames");
	assert (db.getTableNames().length == 1);
	assert (db.getIndexNames().length == 1);
	assert (db.getViewNames().length == 0);

	s2("hasTable, hasView, hasIndex");
	assert (db.hasTable("test") == true);
	assert (db.hasTable("doesnotexist") == false);
	assert (db.hasIndex("doesnotexist") == false);
	assert (db.hasView("doesnotexist") == false);
+/
	s2("close");
	db.close();
}
}

}
