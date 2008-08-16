/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteDatabase;

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
		logger = Log.lookup("dbi.sqlite.Database");
	}

	/**
	 * Create a new instance of SqliteDatabase and open a database.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] dbFile) {
		logger = Log.lookup("dbi.sqlite.Database");
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
			Stdout.formatln("Beginning Sqlite Tests");
			
			auto test = new DBTest(this);
			test.run;
			
			Stdout.formatln("Completed Sqlite Tests");
		}
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
	 *
	 */
	bool hasItem(char[] type, char[] name) {
		auto st = prepare("SELECT name FROM sqlite_master WHERE type=? AND name=?");
		auto row = query(st, type, name).fetch;
		return row !is null ? true : false;
	}
	
	ColumnInfo[] getTableInfo(char[] tablename)
	{
		auto st = prepare("SELECT sql FROM sqlite_master WHERE type='table' AND name=?");
		auto row = query(st, tablename).fetch;
		if(row is null || !row.values.length) return null;
		auto sql = row.values[0];
		debug Stdout.formatln("Sqlite table {} has create SQL: {}", tablename, sql);
		return null;
	}
	
	override SqlGenerator getSqlGenerator()
	{
    	return SqliteSqlGenerator.inst;
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

	+/
}

private class SqliteSqlGenerator : SqlGenerator
{
	static this() { inst = new SqliteSqlGenerator; }
	static SqliteSqlGenerator inst;
	
	char[] toNativeType(ColumnInfo info)
	{
		with(BindType)
		{
			switch(info.type)
			{
			case Bool:
			case Byte:
			case Short:
			case Int:
			case Long:
			case UByte:
			case UShort:
			case UInt:
			case ULong:
				return "INTEGER";
			case Float:
			case Double:
				return "REAL";
			case String:
			case Time:
			case DateTime:
				return "TEXT";
				break;
			case Binary:
				return "BLOB";
				break;
			case Null:
				return "NONE";
			default:
				debug assert(false, "Unhandled column type"); //TODO more detailed information;
				break;
			}
		}
	}
	
	char[] makeColumnDef(ColumnInfo info)
	{
		char[] res = toNativeType(info);
		
		if(info.notNull)	res ~= " NOT NULL"; else res ~= " NULL";
		if(info.primaryKey) res ~= " PRIMARY KEY";
		if(info.autoIncrement) res ~= " AUTOINCREMENT";
		
		return res;
	}
}

private class SqliteRegister : Registerable {
	
	static this() {
		debug(DBITest) Stdout("Attempting to register SqliteDatabase in Registry").newline;
		registerDatabase(new SqliteRegister());
	}
	
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

import tango.io.Stdout;

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
