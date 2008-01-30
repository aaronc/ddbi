/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteDatabase;

version (dbi_sqlite) {


version (Phobos) {
	private import std.string : toDString = toString, toCString = toStringz;
	debug (UnitTest) private import std.stdio;
} else {
	private import tango.stdc.stringz : toDString = fromUtf8z, toCString = toUtf8z;
	private import tango.util.log.Log;
}
private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement, dbi.Registry, dbi.PreparedStatemt;
private import dbi.sqlite.imp, dbi.sqlite.SqliteError, dbi.sqlite.SqliteResult;

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
		logger.trace("connecting: " ~ params);
		if ((errorCode = sqlite3_open(toCString(params), &database)) != SQLITE_OK) {
			throw new DBIException("Could not open or create " ~ params, errorCode, specificToGeneral(errorCode));
		}
	}

	/**
	 * Close the current connection to the database.
	 */
	override void close () {
		logger.trace("closing database now");
		if (database !is null) {
			if ((errorCode = sqlite3_close(database)) != SQLITE_OK) {
				throw new DBIException(asString(sqlite3_errmsg(database)), errorCode, specificToGeneral(errorCode));
			}
			database = null;
		}
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
		logger.trace("executing: " ~ sql);
		char** errorMessage;
		if ((errorCode = sqlite3_exec(database, sql.dup.ptr, null, null, errorMessage)) != SQLITE_OK) {
			throw new DBIException(toDString(sqlite3_errmsg(database)), sql, errorCode, specificToGeneral(errorCode));
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
	override SqliteResult query (char[] sql) {
		logger.trace("querying: " ~ sql);
		char** errorMessage;
		sqlite3_stmt* stmt;
		if ((errorCode = sqlite3_prepare(database, toCString(sql), sql.length, &stmt, errorMessage)) != SQLITE_OK) {
			throw new DBIException(toDString(sqlite3_errmsg(database)), sql, errorCode, specificToGeneral(errorCode));
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
		return sqlite3_errcode(database);
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
		return toDString(sqlite3_errmsg(database));
	}

	/**
	 * Get the integer id of the last row to be inserted.
	 *
	 * Returns:
	 *	The id of the last row inserted into the database.
	 */
	override long getLastInsertID() {
		return sqlite3_last_insert_rowid(database);
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
	sqlite3* database;
	bool isOpen = false;
	int errorCode;

	/**
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
	}
	
	IPreparedStatement createStatement(char[] statement)
	{
		sqlite3_stmt* stmt;
		char* pzTail;
		int res;
		if((res = sqlite3_prepare_v2(database, toCString(statement), statement.length, &stmt, &pzTail)) != SQLITE_OK) {
			char* errmsg = sqlite3_errmsg(db_);
			logger.error("sqlite3_prepare_v2 for statement: \"" ~ statement ~ "\" returned: " ~ Integer.toUtf8(res) ~ ", errmsg: " ~ toDString(errmsg));
			return null;
		}
		return new SqlitePreparedStatement(stmt, database);
	}
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

class SqlitePreparedStatement : IPreparedStatement
{
	static Logger logger;
	static this()
	{
		logger = Log.getLogger("sendero.data.backends.Sqlite.SqlitePreparedStatement");
	}
	
	private this(sqlite3_stmt* stmt, sqlite3* db)
	{
		this.stmt = stmt;
		this.db = db;
	}
	
	~this()
	{
		sqlite3_finalize(stmt);
	}
	
	
	private sqlite3_stmt* stmt;
	package sqlite3* db;
	private BindType[] paramTypes;
	private BindType[] resTypes;
	private bool row = false;
	private bool wasReset = false;
	
	int setParamTypes(BindType[] paramTypes)
	{
		this.paramTypes = paramTypes;
	}
	
	int setResultTypes(BindType[] resTypes)
	{
		this.resTypes = resTypes;	
	}
	
	bool execute(StatementBinder binder)
	{
		uint i = 0;
		foreach(p; paramTypes)
		{
			void* x;
			size_t len;
			binder(i, p, x, len);
			switch(p)
			{
			case BindType.Bool:
				if(sqlite3_bind_int(stmt, index + 1, *(cast(bool*)x)) != SQLITE_OK) return false;
				break;
			case BindType.Byte:
				if(sqlite3_bind_int(stmt, index + 1, *(cast(byte*)x)) != SQLITE_OK) return false;
				break;
			case BindType.Short:
				if(sqlite3_bind_int(stmt, index + 1, *(cast(short*)x)) != SQLITE_OK) return false;
				break;
			case BindType.Int:
				if(sqlite3_bind_int(stmt, index + 1, *(cast(int*)x)) != SQLITE_OK) return false;
				break;
			case BindType.Long:
				if(sqlite3_bind_int64(stmt, index + 1, *(cast(long*)x)) != SQLITE_OK) return false;
				break;
			case BindType.UByte:
				if(sqlite3_bind_int(stmt, index + 1, *(cast(bool*)x)) != SQLITE_OK) return false;
				break;
			case BindType.UShort:
				if(sqlite3_bind_int(stmt, index + 1, *(cast(ubyte*)x)) != SQLITE_OK) return false;
				break;
			case BindType.UInt:
				if(sqlite3_bind_int64(stmt, index + 1, *(cast(uint*)x)) != SQLITE_OK) return false;
				break;
			case BindType.ULong:
				if(sqlite3_bind_int64(stmt, index + 1, *(cast(ulong*)x)) != SQLITE_OK) return false;
				break;
			case BindType.Float:
				if(sqlite3_bind_double(stmt, index + 1,  *(cast(float*)x)) != SQLITE_OK) return false;
				break;
			case BindType.Double:
				if(sqlite3_bind_double(stmt, index + 1,  *(cast(double*)x)) != SQLITE_OK) return false;
				break;
			case BindType.String:
				if(sqlite3_bind_text(stmt, index + 1, *cast(char**)x, len, null) != SQLITE_OK) return false;
				break;
			case BindType.UByteArray:
			case BindType.VoidArray:
				if(sqlite3_bind_blob(stmt, index + 1, *cast(void**)x, len, null) != SQLITE_OK) return false;
				break;
			case BindType.DateTime:
				break;
			case BindType.Date:
				break;
			case BindType.Time:
				break;
			default:
				debug assert(false);
				break;
			}
			++i;
		}
		
		int ret = sqlite3_step(stmt);
		wasReset = false;
		switch(ret)
		{
			case SQLITE_ROW:
				row = true;
				return true;
			case SQLITE_DONE:
				row = false;
				return true;
			case SQLITE_BUSY:
			default:
				row = false;
				return false;
		}
	}
	
	bool fetch(StatementBinder binder)
	{
		if(!row) return false;
		int ret = sqlite3_step(stmt);
		wasReset = false;
		
		uint index = 0;
		foreach(r; resTypes)
		{
			void* x;
			size_t len;
			binder(index, r, x, len);
			switch(p)
			{
			case BindType.Bool:
				int z = sqlite3_column_int(stmt, index);
				*cast(bool*)x = cast(bool)z;
				break;
			case BindType.Byte:
				int z = sqlite3_column_int(stmt, index);
				*cast(byte*)x = cast(byte)z;
				break;
			case BindType.Short:
				int z = sqlite3_column_int(stmt, index);
				*cast(short*)x = cast(short)z;
				break;
			case BindType.Int:
				int z = sqlite3_column_int(stmt, index);
				*cast(int*)x = z;
				break;
			case BindType.Long:
				long z = sqlite3_column_int64(stmt, index);
				*cast(long*)x = z;
				break;
			case BindType.UByte:
				int z = sqlite3_column_int(stmt, index);
				*cast(ubyte*)x = cast(ubyte)z;
				break;
			case BindType.UShort:
				int z = sqlite3_column_int(stmt, index);
				*cast(ushort*)x = cast(ushort)z;
				break;
			case BindType.UInt:
				long z = sqlite3_column_int64(stmt, index);
				*cast(uint*)x = cast(uint)z;
				break;
			case BindType.ULong:
				long z = sqlite3_column_int64(stmt, index);
				*cast(ulong*)x = cast(ulong)z;
				break;
			case BindType.Float:
				double z = sqlite3_column_int(stmt, index);
				*cast(float*)x = cast(float)z;
				break;
			case BindType.Double:
				double z = sqlite3_column_int(stmt, index);
				*cast(double*)x = z;
				break;
			case BindType.String:
				char[] z = fromCStringz(sqlite3_column_text(stmt, index));
				*cast(char**)x = z.ptr;
				len = z.length;
				break;
			case BindType.UByteArray:
			case BindType.VoidArray:
				void* res = sqlite3_column_blob(stmt, index);
				len = sqlite3_column_bytes(stmt, index);
				*cast(char**)x = len ? res[0 .. len] : null;
				break;
			case BindType.DateTime:
				break;
			case BindType.Date:
				break;
			case BindType.Time:
				break;
			default:
				debug assert(false);
				break;
			}
			++i;
		}
		
		row = (ret == SQLITE_ROW);
		return true;
	}
	
	void reset()
	{
		if(!wasReset) {
			sqlite3_reset(stmt);
			wasReset = true;
		}
	}
	
	ulong getLastInsertID()
	{
		long id = sqlite3_last_insert_rowid(db);
		return cast(ulong)id;
	}
}

static this() {
	auto logger = Log.getLogger("dbi.sqlite");
	logger.trace("Attempting to register SqliteDatabase in Registry");
	registerDatabase(new SqliteRegister());
}

unittest {
	version (Phobos) {
		void s1 (char[] s) {
			std.stdio.writefln("%s", s);
		}

		void s2 (char[] s) {
			std.stdio.writefln("   ...%s", s);
		}
	} else {
		void s1 (char[] s) {
			tango.io.Stdout.Stdout(s).newline();
		}

		void s2 (char[] s) {
			tango.io.Stdout.Stdout("   ..." ~ s).newline();
		}
	}

	s1("dbi.sqlite.SqliteDatabase:");
	SqliteDatabase db = new SqliteDatabase();
	s2("connect");
	db.connect("test.db");

	s2("query");
	Result res = db.query("SELECT * FROM test");
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

	s2("close");
	db.close();
}

}