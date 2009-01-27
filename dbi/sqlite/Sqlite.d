/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.sqlite.Sqlite;

private import tango.stdc.stringz : toDString = fromStringz, toCString = toStringz;
private import tango.util.log.Log;
    
public import dbi.model.Database;
import dbi.Exception, dbi.model.Statement, dbi.util.Registry;
import dbi.util.Excerpt;

import dbi.sqlite.imp, dbi.sqlite.SqliteError;
import dbi.sqlite.SqliteStatement; 

import tango.core.Thread;
import Integer = tango.text.convert.Integer;

/**
 * An implementation of Database for use with SQLite databases.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class Sqlite : Database {
	
	private Logger logger;
	public:

	/**
	 * Create a new instance of Sqlite, but don't open a database.
	 */
	this () {
		stepFiber_ = new Fiber(&stepFiberRoutine,short.max);
		logger = Log.lookup("dbi.sqlite.Sqlite");
		debug logger.info("Sqlite lib version {}", toDString(sqlite3_libversion));
	}

	/**
	 * Create a new instance of Sqlite and open a database.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] dbFile) {
		this();
		connect(dbFile);
	}
	
	~this() {
		close;
	}
	
	char[] type() { return "Sqlite"; }

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
	 *	auto db = new Sqlite();
	 *	db.connect("_test.db");
	 *	---
	 */
	void connect (char[] dbfile) {
		logger.trace("connecting: " ~ dbfile);
		if ((errorCode = sqlite3_open(toCString(dbfile), &sqlite_)) != SQLITE_OK) {
			throw new DBIException("Could not open or create " ~ dbfile, errorCode, specificToGeneral(errorCode));
		}
	}

	/**
	 * Close the current connection to the database.
	 */
	override void close () {
		logger.trace("closing database now");
		if (sqlite_ !is null) {
			while(lastSt) {
				lastSt.close;
				lastSt = lastSt.lastSt;
			}
			
			if ((errorCode = sqlite3_close(sqlite_)) != SQLITE_OK) {
				throw new DBIException(toDString(sqlite3_errmsg(sqlite_)), errorCode, specificToGeneral(errorCode));
			}
			sqlite_ = null;
		}
	}
	
	Statement doPrepare(char[] sql)
	{
		auto stmt = doPrepareRaw(sql);
		
		lastSt = new SqliteStatement(sqlite_, stmt, sql, lastSt);
		return lastSt;
	}
	
	private sqlite3_stmt* doPrepareRaw(char[] sql)
	{
		debug logger.trace("Preparing: {}", excerpt(sql_));
		char* errorMessage;
		sqlite3_stmt* stmt;
		if ((errorCode = sqlite3_prepare_v2(sqlite_, toCString(sql), sql.length, &stmt, &errorMessage)) != SQLITE_OK) {
			throw new DBIException("sqlite3_prepare_v2 error: " ~ toDString(sqlite3_errmsg(sqlite_)), sql, errorCode, specificToGeneral(errorCode));
		}
		return stmt;
	}
	
	alias SqliteStatement StatementT;
	
	private SqliteStatement lastSt = null;
			
	/+override void execute (char[] sql) {
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
	}+/

	/**
	 * Get the number of rows affected by the last SQL statement.
	 *
	 * Returns:
	 *	The number of rows affected by the last SQL statement.
	 */
	ulong affectedRows () {
		return sqlite3_changes(sqlite_);
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
	
	void startTransaction()
	{
		execute("BEGIN");
	}
	
	void rollback()
	{
		execute("ROLLBACK");
	}
	
	void commit()
	{
		execute("COMMIT");
	}
	
	debug(DBITest) {
		override void doTests()
		{
			Stdout.formatln("Beginning Sqlite Tests");
			
			auto test = new SqliteTest(this);
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
		query("SELECT name FROM sqlite_master WHERE type=? AND name=?",
							type, name);
		auto has = rowCount > 0 ? true : false;
		closeResult;
		return has;
	}
	
	/+ColumnInfo[] getTableInfo(char[] tablename)
	{	
		auto res = query("PRAGMA table_info('" ~ tablename ~ "')");
		
		ColumnInfo[] info;
		auto row = res.fetch;
		while(row) {
			if(row.values.length < 6) break;
			
			ColumnInfo col;
			col.name = row.values[1];
			col.type = fromSqliteType(row.values[2]);
			if(row.values[3] != "0") col.notNull = true;
			if(row.values[5] == "1") col.primaryKey = true;
				
			info ~= col;
			
			row = res.fetch;
		}
		
		res.finalize;
		
		return info;
	}+/
	
	bool moreResults()
	{
		return false;
	}
	
	bool nextResult()
	{
		return false;
	}
	
	bool validResult()
	{
		return lastRes_ == SQLITE_ROW ? true : false;
	}
	
	void closeResult()
	{
		while(stepFiber_.state != Fiber.State.TERM) {
			stepFiber_.call(true);
		}
	}
	
	ulong rowCount()
	{
		return sqlite3_data_count(stmt_);
	}
	
	ulong fieldCount()
	{
		return sqlite3_column_count(stmt_);
	}
	
	FieldInfo[] rowMetadata()
	{
		auto fieldCount = sqlite3_column_count(stmt_);
		FieldInfo[] fieldInfo;
		for(int i = 0; i < fieldCount; ++i)
		{
			FieldInfo info;
			
			info.name = toDString(sqlite3_column_name(stmt_, i));
			info.type = SqliteStatement.fromSqliteType(sqlite3_column_type(stmt_, i));
			
			fieldInfo ~= info;
		}
		
		return fieldInfo;
	}
	
	bool nextRow()
	{
		/+lastRes_ = sqlite3_step(stmt_);
		return lastRes_ == SQLITE_ROW ? true : false;+/
		if(stepFiber_.state == Fiber.State.TERM) return false;
		stepFiber_.call(true);
		return lastRes_ == SQLITE_ROW ? true : false;
	}
	
	private const char[] OutOfSyncQueryErrorMsg =
		"Commands out of sync - cannot run a new sqlite "
		"query until you have finshed cycling through all result rows "
		"using fetch() or by calling closeResult() to close the current query.";
	
	void initQuery(in char[] sql, bool haveParams)
	{
		/+if(stepFiber_.state != Fiber.State.HOLD)
			throw new DBIException(OutOfSyncQueryErrorMsg,
				sql_,ErrorCode.OutOfSync);+/
		if(stepFiber_.state == Fiber.State.TERM)
			stepFiber_.reset;
		if(stepFiber_.state != Fiber.State.HOLD)
			throw new DBIException(OutOfSyncQueryErrorMsg,
				sql_,ErrorCode.OutOfSync);
		sql_ = sql;
		debug assert(stmt_ is null);
		stmt_ = doPrepareRaw(sql);
		assert(stmt_ !is null);
		numParams_ = sqlite3_bind_parameter_count(stmt_);
		curParamIdx_ = 0;
	}
	
	void doQuery()
	{
		if(stepFiber_.state != Fiber.State.HOLD)
			throw new DBIException(OutOfSyncQueryErrorMsg,
				sql_,ErrorCode.OutOfSync);
		curParamIdx_ = -1;
		stepFiber_.call(true);
	}
	
	private void stepFiberRoutine()
	{
		bool checkRes() {
			debug logger.trace("Checking res {}", lastRes_);
			if(lastRes_ == SQLITE_DONE) {
				debug logger.trace("No more rows");
				return false;
			}
			else if(lastRes_ != SQLITE_ROW) {
				assert(false, "Error");
			}
			else {
				debug logger.trace("Have a row");
				return true;
			}
		}
		
		try
		{
			assert(stmt_ !is null);
			debug logger.trace("Executing {}",excerpt(sql_));
			lastRes_ = sqlite3_step(stmt_);
			if(!checkRes) return;
			Fiber.yield;
			numFields_ = sqlite3_column_count(stmt_);
			Fiber.yield;
			while(lastRes_ == SQLITE_ROW) {
				assert(stmt_ !is null);
				lastRes_ = sqlite3_step(stmt_);
				if(!checkRes) return;
				Fiber.yield;
			}
		}
		catch(Exception ex)
		{
			debug logger.error("Caught exception in stepFiberRoutine {}", ex.toString);
			//throw ex;
			Fiber.yieldAndThrow(ex);
		}
		finally
		{
			debug logger.trace("Cleaning up after {}",excerpt(sql_));
			numFields_ = 0;
			if(stmt_ !is null) {
				debug logger.trace("Finalizing stmt_");
				sqlite3_finalize(stmt_);
				stmt_ = null;
			}
		}
	}
	
	ulong lastInsertID() in { assert(sqlite_ !is null); }
	body {
		/+auto id = sqlite3_last_insert_rowid(sqlite_);
		if(id == 0)	return 0;
		else return cast(ulong)id;+/
		return sqlite3_last_insert_rowid(sqlite_);
	}
	
	static BindType fromSqliteType(char[] str)
	{
		switch(str)
		{
		case "TEXT": return BindType.String;
		case "BLOB": return BindType.Binary;
		case "INTEGER": return BindType.Long;
		case "REAL": return BindType.Double;
		case "NONE":
		default:
			return BindType.Null;
		}
	}
/+	
	bool bindField(Type)(inout Type val, size_t idx)
	{
		if(stmt_ is null || lastRes_ != SQLITE_ROW || numFields_ <= idx) return false;
		static if(is(Type == bool))
			{ val = sqlite3_column_int(stmt_,idx) == 0 ? false : true; }
		else static if(is(Type == ubyte) || is(Type == byte) || is(Type == ushort)
			|| is(Type == short) || is(Type == int)) 
			{ val = sqlite3_column_int(stmt_,idx); }
		else static if(is(Type == uint) || is(Type == long) || is(Type == ulong))
			{ val = sqlite3_column_int64(stmt_,idx)l }
		else static if(is(Type == float) || is(Type == double))
			{ val = sqlite3_column_double(stmt_,idx); }
		else static if(is(Type == void[]) || is (Type == ubyte[]))
		{
			auto res = sqlite3_column_blob(stmt, index);
			auto len = sqlite3_column_bytes(stmt, index);
			*val = res[0 .. len].dup;
		}
		return true;
	}+/
	
/+	
	bool getField(inout bool val, size_t idx)
	{
		if(stmt_ is null || lastRes_ != SQLITE_ROW || numFields_ <= idx) return false;
		val = sqlite3_column_int(stmt_,idx) == 0 ? false : true;
		return true;
	}
	
	bool getField(inout ubyte val, size_t idx)
	{
		if(stmt_ is null || lastRes_ != SQLITE_ROW || numFields_ <= idx) return false;
		val = sqlite3_column_int(stmt_,idx);
		return true;
	}
	
	bool getField(inout byte, size_t idx)
	{
		if(stmt_ is null || lastRes_ != SQLITE_ROW || numFields_ <= idx) return false;
		val = sqlite3_column_int(stmt_,idx);
		return true;
	}
	
	abstract bool getField(inout ushort, size_t idx);
	abstract bool getField(inout short, size_t idx);
	abstract bool getField(inout uint, size_t idx);
	abstract bool getField(inout int, size_t idx);
	abstract bool getField(inout ulong, size_t idx);
	abstract bool getField(inout long, size_t idx);
	abstract bool getField(inout float, size_t idx);
	abstract bool getField(inout double, size_t idx);
	abstract bool getField(inout char[], size_t idx);
	abstract bool getField(inout ubyte[], size_t idx);
	abstract bool getField(inout Time, size_t idx);
	abstract bool getField(inout DateTime, size_t idx);+/
	
	bool bindField(Type)(inout Type val, size_t idx)
	{
		debug logger.trace("Binding field of type {}, idx {}", Type.stringof, idx);
		if(stmt_ is null || lastRes_ != SQLITE_ROW || numFields_ <= idx) return false;
		SqliteStatement.bindT!(Type,false)(stmt_,val,idx);
		return true;
	}
	
	bool getField(inout bool val, size_t idx) { return bindField(val, idx); }    
	bool getField(inout ubyte val, size_t idx) { return bindField(val, idx); }
	bool getField(inout byte val, size_t idx) { return bindField(val, idx); }
	bool getField(inout ushort val, size_t idx) { return bindField(val, idx); }
	bool getField(inout short val, size_t idx) { return bindField(val, idx); }
	bool getField(inout uint val, size_t idx) { return bindField(val, idx); }
	bool getField(inout int val, size_t idx) { return bindField(val, idx); }
	bool getField(inout ulong val, size_t idx) { return bindField(val, idx); }
	bool getField(inout long val, size_t idx) { return bindField(val, idx); }
	bool getField(inout float val, size_t idx) { return bindField(val, idx); }
	bool getField(inout double val, size_t idx) { return bindField(val, idx); }
	bool getField(inout char[] val, size_t idx) { return bindField(val, idx); }
	bool getField(inout ubyte[] val, size_t idx) { return bindField(val, idx); }
	bool getField(inout Time val, size_t idx) { return bindField(val, idx); }
	bool getField(inout DateTime val, size_t idx) { return bindField(val, idx); }
	
	void setParamT(Type,bool Null = false)(Type val)
	{
		if(stmt_ is null || numParams_ <= curParamIdx_)
			throw new DBIException(
				"Param index " ~ Integer.toString(curParamIdx_) ~ " of type "
				~ Type.stringof ~ "out of bounds "
				"when binding sqlite param",sql_);
		if(curParamIdx_ < 0) {
			throw new DBIException(
				"Trying to bind parameter of type"
				~ Type.stringof ~ "to sqlite statement "
				"but this operation is out of sync - you can't do this right now. "
				"Please check the order of your statements.",sql_);
		}
		static if(Null) SqliteStatement.bindNull!(true)(stmt_,curParamIdx_);
		else SqliteStatement.bindT!(Type,true)(stmt_,val,curParamIdx_);
		++curParamIdx_;
	}
	
	void setParam(bool val) { setParamT(val); }
	void setParam(ubyte val) { setParamT(val); }
	void setParam(byte val) { setParamT(val); }
	void setParam(ushort val) { setParamT(val); }
	void setParam(short val) { setParamT(val); }
	void setParam(uint val) { setParamT(val); }
	void setParam(int val) { setParamT(val); }
	void setParam(ulong val) { setParamT(val); }
	void setParam(long val) { setParamT(val); }
	void setParam(float val) { setParamT(val); }
	void setParam(double val) { setParamT(val); }
	void setParam(char[] val) { setParamT(val); }
	void setParam(ubyte[] val) { setParamT(val); }
	void setParam(Time val) { setParamT(val); }
	void setParam(DateTime val) { setParamT(val); }
	void setParamNull() { setParamT!(void*,true)(null); }
	
	
	bool enabled(DbiFeature feature) { return false; }
	
	void initInsert(char[] tablename, char[][] fields)
	{
		//assert(false);
		/+char[] writer_;
		writer_ ~= "INSERT INTO \"";
		writer_ ~= tablename;
		writer_ ~= "\" ";
		bool first = true;
		foreach(field; fields)
		{
			if(!first) writer ~= ",\"";
			else writer_ ~= "\"";
			writer_ ~= field;
			writer_ ~= "\"";
			first = false;
		}+/
		initQuery(SqlGenHelper.makeInsertSql(tablename,fields),true);
	}
	
	void initUpdate(char[] tablename, char[][] fields, char[] where)
	{
		//assert(false);
		initQuery(SqlGenHelper.makeUpdateSql(where,tablename,fields),true);
	}
	
	void initSelect(char[] tablename, char[][] fields, char[] where, bool haveParams)
	{
		//initQuery(SqlGenHelper.makeUpdateSql(tablename,fields));
		assert(false);
	}
	
	void initRemove(char[] tablename, char[] where, bool haveParams)
	{
		//initQuery(sqlGen.makeUpdateSql(where,tablename,fields));
		assert(false);
	}
	
	bool startWritingMultipleStatements()
	{
		return false;
	}
	
	bool isWritingMultipleStatements()
	{
		return false;
	}
	
	char[] escapeString(in char[] str, char[] dst = null)
	{
		assert(false);
	}
	
	ColumnInfo[] getTableInfo(char[] tablename)
	{
		assert(false);
	}
	
	override SqlGenerator getSqlGenerator()
	{
    	return SqliteSqlGenerator.inst;
	}
	
	sqlite3* handle() { return sqlite_; }
	
	private:
		sqlite3* sqlite_;
		sqlite3_stmt* stmt_;
		char[] sql_;
	//	bool isOpen = false;
		int errorCode;
		int lastRes_;
		Fiber stepFiber_;
		int numFields_;
		int numParams_;
		int curParamIdx_;

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
	
	char[] makeColumnDef(ColumnInfo info, ColumnInfo[] columnInfo)
	{
		char[] res = toNativeType(info);
		
		bool multiPKey = false;
		foreach(col; columnInfo) if(col.primaryKey && col.name != info.name) {
			multiPKey = true;
			break;
		}
		
		if(info.notNull)	res ~= " NOT NULL"; else res ~= " NULL";
		if(info.primaryKey && !multiPKey) res ~= " PRIMARY KEY";
		if(info.autoIncrement) res ~= " AUTOINCREMENT";
		
		return res;
	}
}

private class SqliteRegister : IRegisterable {
	
	static this() {
		debug(DBITest) Stdout("Attempting to register Sqlite in Registry").newline;
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
		return new Sqlite(url);
	}
}

debug(DBITest) {

import tango.io.Stdout;

class SqliteTest : DBTest
{
	this(Sqlite db)
	{ super(db); }
	
	void dbTests()
	{
		auto ti = db.getTableInfo("dbi_test"); 
		assert(ti);
		assert(ti.length == 6);
		
		assert(ti[0].name == "id");
		assert(ti[0].type == BindType.Long);
		assert(ti[0].notNull == true);
		assert(ti[0].primaryKey == true);
		
		assert(ti[1].name == "name");
		assert(ti[1].type == BindType.String);
		assert(ti[1].notNull == true);
		assert(ti[1].primaryKey == false);
		
		assert(ti[2].name == "binary");
		assert(ti[2].type == BindType.Binary);
		assert(ti[2].notNull == false);
		assert(ti[2].primaryKey == false);
		
		assert(ti[3].name == "dateofbirth");
		assert(ti[3].type == BindType.String);
		assert(ti[3].notNull == false);
		assert(ti[3].primaryKey == false);
		
		assert(ti[4].name == "i");
		assert(ti[4].type == BindType.Long);
		assert(ti[4].notNull == false);
		assert(ti[4].primaryKey == false);
		
		assert(ti[5].name == "f");
		assert(ti[5].type == BindType.Double);
		assert(ti[5].notNull == false);
		assert(ti[5].primaryKey == false);
	}
}


unittest {
    void s1 (char[] s) {
        tango.io.Stdout.Stdout(s).newline();
    }

    void s2 (char[] s) {
        tango.io.Stdout.Stdout("   ..." ~ s).newline();
    }

	s1("dbi.sqlite.Sqlite:");
	Sqlite db = new Sqlite();
	s2("connect");
	db.connect("test.sqlite");

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