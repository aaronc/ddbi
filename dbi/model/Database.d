/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.model.Database;

private static import tango.text.Util;
private static import tango.io.Stdout;
import tango.core.Vararg;

public import dbi.Exception;
public import dbi.util.SqlGen, dbi.model.Statement, dbi.model.Metadata, dbi.model.Result;
import dbi.util.Excerpt;
import dbi.util.StringWriter;

debug(DBITest) public import tango.io.Stdout;

import tango.util.log.Log;
private static Logger log;
static this() {
	log = Log.lookup("dbi.model.Database");
}

///
enum DbiFeature
{
	///
    MultiStatements 
}


/**
 * The database interface that all databases must inherit from.
 *
 * See_Also:
 *  The documentation for dbi.model.Result - Database inherits from Result.
 * 
 *	The database class for the specific database you are using.  Many databases have
 *	functions that are specific to themselves, as they wouldn't make sense in any man
 *	other databases.  Please reference the documentation for the database you will be
 *	using to discover these functions.
 */
abstract class Database : Result, IStatementProvider {
	
	/**
	 *	Sends a query to the database server.  Queries can use ? to represent
	 *	parameters that will be filled in by the variadic argument parameters
	 *	that can be passed to query.
	 *
	 *	Arguments of the following types can be used as bind arguments:
			bool
			byte
			ubyte
			short
			ushort
			int
			uint
			long
			ulong
			float
			double
			char[]
			void[]
			ubyte[]
			tango.time.Time
			tango.time.DateTime
			dbi.model.BindType.BindInfo
			
		Examples:
		----------
		db.query("SELECT name FROM user WHERE id = ?", 15);
		
		uint limit = 15;
		uint offset = 100;
		db.query("SELECT id,name FROM user WHERE 1 LIMIT ? OFFSET ?", limit, offset);
		----------
		
		Params:
			sql = The sql query that will be sent to the server, can use ?'s to represent
			parameters that will be bound autmotically by DBI using the variadic parameters
			passed by bind.
			bind = Variadic arguments that bind to ?'s used in the query text.  (optional)
			
		Returns: true if the query was successful, false otherwise
		Throws: DBIException on a serious error executing the query
	 */
	void query(Types...)(in char[] sql, Types bind)
	{
		static if(Types.length) {
			initQuery(sql, true);
			setParams(bind);			
		}
		else initQuery(sql, false);
	
		return doQuery();
	}
	
	/// Alias for query
	alias query execute;

	///
	void insert(Types...)(char[] tablename, char[][] fields, Types bind)
	{
		initInsert(tablename, fields);
		setParams(bind);			
		return doQuery();
	}
	
	///
	void update(Types...)(char[] tablename, char[][] fields, char[] where, Types bind)
	{
		initUpdate(tablename, fields, where);
		setParams(bind);
		return doQuery();
	}
	
	///
	void select(Types...)(char[] tablename, char[][] fields, char[] where, Types bind)
	{
		bool haveParams = Types.length ? true : false;
		initSelect(tablename, fields, where, haveParams);
		setParams(bind);
		return doQuery();
	}
	
	///
	void remove(Types...)(char[] tablename, char[] where, Types bind)
	{
		bool haveParams = Types.length ? true : false;
		initRemove(tablename, where, haveParams);
		setParams(bind);
		return doQuery();
	}
	
	/**
	 */
	abstract ulong lastInsertID();
		
	/**
	 * Prepares a statement with the given sql
	 */
	Statement prepare(char[] sql)
	{
		auto pSt = sql in cachedStatements;
		if(pSt) {
			return *pSt;
		}
		auto st = doPrepare(sql);
		cachedStatements[sql] = st;
		st.setCacheProvider(this);
		return st;
	}
	protected Statement[char[]] cachedStatements;
	
	/**
	 * A destructor that attempts to force the the release of of all
	 * database connections and similar things.
	 *
	 * The current D garbage collector doesn't always call destructors,
	 * so it is HIGHLY recommended that you close connections manually.
	 */
	~this () {
		try
		{
			/+foreach(key, st; cachedStatements)
				st.close;+/
			close();
		}
		catch(Exception ex)
		{
			log.error("Error closing database {}", ex.toString);
		}
	}
	
//	abstract Result detachResult();

   /**
     * Returns true if the given feature has been enabled in
     * this Database instance.
     */
   abstract bool enabled(DbiFeature feature);
	
	/**
	 * Close the current connection to the database.
	 */
	abstract void close();	
	
	
	
	///
	void uncacheStatement(Statement st)
	{
		uncacheStatement(st.sql);
	}
	
	///
	void uncacheStatement(char[] sql)
	{
		auto pSt = sql in cachedStatements;
		if(pSt) {
			cachedStatements.remove(sql);
		}
	}
	
	///
	abstract char[] escapeString(in char[] str, char[] dst = null);
	
	///
	abstract void startTransaction();

	/// Alias for startTransaction
	alias startTransaction begin;
	
	///
	abstract void rollback();
	
	///
	abstract void commit();
  
	/**
	 * Split a _string into keywords and values.
	 *
	 * Params:
	 *	string = A _string in the form keyword1=value1;keyword2=value2;etc.
	 *
	 * Returns:
	 *	An associative array containing keywords and their values.
	 *
	 * Throws:
	 *	DBIException if string is malformed.
	 */
	final protected char[][char[]] getKeywords (char[] string, char[] split = ";") {
		char[][char[]] keywords;
		foreach (char[] group; tango.text.Util.delimit(string, split)) {
			if (group == "") {
				continue;
			}
			char[][] vals = tango.text.Util.delimit(group, "=");
			keywords[vals[0]] = vals[1];
		}
		return keywords;
	}
	
	///
	abstract bool hasTable(char[] tablename);

	///
	abstract ColumnInfo[] getTableInfo(char[] tablename);
	
	///
	abstract SqlGenerator getSqlGenerator();
	
	/// Alias for getSqlGenerator
	alias getSqlGenerator sqlGen;
	
	alias Statement StatementT;
	
	/**
	 * 
	 * Returns: The database type for this instance (i.e. Mysql, Sqlite, Postgresql, etc.)
	 */
	abstract char[] type();
	
	///
	abstract void initQuery(in char[] sql, bool haveParams);
	///
	abstract void doQuery();
	
	///
	abstract void setParam(bool);
	///
	abstract void setParam(ubyte);
	///
	abstract void setParam(byte);
	///
	abstract void setParam(ushort);
	///
	abstract void setParam(short);
	///
	abstract void setParam(uint);
	///
	abstract void setParam(int);
	///
	abstract void setParam(ulong);
	///
	abstract void setParam(long);
	///
	abstract void setParam(float);
	///
	abstract void setParam(double);
	///
	abstract void setParam(char[]);
	///
	abstract void setParam(ubyte[]);
	///
	abstract void setParam(Time);
	///
	abstract void setParam(DateTime);
	///
	abstract void setParamNull();
	
	///
	void setParams(...)
	{
		for(int i = 0; i < _arguments.length; ++i)
		{
			if(_arguments[i] == typeid(bool))
				setParam(va_arg!(bool)(_argptr));
			
			else if(_arguments[i] == typeid(ubyte))
				setParam(va_arg!(ubyte)(_argptr));
			
			else if(_arguments[i] == typeid(byte))
				setParam(va_arg!(byte)(_argptr));
			
			else if(_arguments[i] == typeid(ushort))
				setParam(va_arg!(ushort)(_argptr));
			
			else if(_arguments[i] == typeid(short))
				setParam(va_arg!(short)(_argptr));
			
			else if(_arguments[i] == typeid(uint))
				setParam(va_arg!(uint)(_argptr));
			
			else if(_arguments[i] == typeid(int))
				setParam(va_arg!(int)(_argptr));
			
			else if(_arguments[i] == typeid(ulong))
				setParam(va_arg!(ulong)(_argptr));
				
			else if(_arguments[i] == typeid(long))
				setParam(va_arg!(long)(_argptr));
			
			else if(_arguments[i] == typeid(float))
				setParam(va_arg!(float)(_argptr));
			
			else if(_arguments[i] == typeid(double))
				setParam(va_arg!(double)(_argptr));
			
			else if(_arguments[i] == typeid(ubyte[]))
				setParam(va_arg!(ubyte[])(_argptr));
			
			else if(_arguments[i] == typeid(void[]))
				setParam(va_arg!(ubyte[])(_argptr));
			
			else if(_arguments[i] == typeid(char[]))
				setParam(va_arg!(char[])(_argptr));
			
			else if(_arguments[i] == typeid(Time))
				setParam(va_arg!(Time)(_argptr));
			
			else if(_arguments[i] == typeid(DateTime))
				setParam(va_arg!(DateTime)(_argptr));
			
			else if(_arguments[i] == typeid(BindInfo))
			{
				auto bindInfo = va_arg!(BindInfo)(_argptr);
				
				auto ptrs = bindInfo.ptrs;
	    		foreach(j, type; bindInfo.types)
	    		{
	    			switch(type)
	    			{
	    			case BindType.Bool:
	    				bool* ptr = cast(bool*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Byte:
	    				byte* ptr = cast(byte*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Short:
	    				short* ptr = cast(short*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Int:
	    				int* ptr = cast(int*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Long:
	    				long* ptr = cast(long*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.UByte:
	    				ubyte* ptr = cast(ubyte*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.UShort:
	    				ushort* ptr = cast(ushort*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.UInt:
	    				uint* ptr = cast(uint*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.ULong:
	    				ulong* ptr = cast(ulong*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Float:
	    				float* ptr = cast(float*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Double:
	    				double* ptr = cast(double*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.String:
	    				char[]* ptr = cast(char[]*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Binary:
	    				ubyte[]* ptr = cast(ubyte[]*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Time:
	    				Time* ptr = cast(Time*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.DateTime:
	    				DateTime* ptr = cast(DateTime*)ptrs[j];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Null:
	    			default:
	    				setParamNull();
	    				break;
	    			}
	    		}
			}
			else debug assert(false, "Unknown bind type " ~ _arguments[i].toString);
		}
	}
	
	///
	abstract void initInsert(char[] tablename, char[][] fields);
	
	///
	abstract void initUpdate(char[] tablename, char[][] fields, char[] where);
	
	///
	abstract void initSelect(char[] tablename, char[][] fields, char[] where, bool haveParams);
	
	///
	abstract void initRemove(char[] tablename, char[] where, bool haveParams);
	
	/**
	 * Initializes the writing of multiple statements using DBI's Sql generation
	 * interface.
	 * 
	 * Should only be called once before writing any statements for the given query.
	 * Note that there should be no danger in calling startWritingMultipleStatements()
	 * when only one statement is actually written.  Multi-statement must be done in this
	 * order -
	 * 
	 * ---
	 *  // startWritingMultipleStatements
	 *  
	 *  // for each statement that is to be written:
     *		// initQuery() or one of its variants initInsert, initUpdate, initSelect, or initRemove
     *		// is called for the statement that is being written
     *
     * 		// setParams, setParam, or setParamNull are called the correct number of times 
     * 		// for the given statement
     * 
     *  // doQuery is called to send the full query to the server and execute it
     * ---
     *  
     *  Example:
     *  ---
		db.startWritingMultipleStatements;
		
			db.initInsert("myTable", ["number", "name"]);
			db.setParams(15,"bob");
			
			db.initSelect("myTable",["number", "name"],"WHERE 1",false);
			
		db.doQuery;
		---
     *  
     *  The call to doQuery() ends the writing of multiple statements and executes
     *  all of the statements that were written since the call to
     *  startWritingMultipleStatements().
     *  startWritingMultipleStatements() will have to be called again to enable it
     *  for the next query.
     *  If a query is written using (initQuery and setParam(s)) and
     *  startWritingMultipleStatements() is called afterwards, that query
     *  will be lost.
	 *  
	 * Returns: true if multiple statement writing was successfully initialized,
	 * 	false if the database doesn't support this feature
	 * Throws: DBIException if the database does support this feature but the
	 * 	command was called out of order (i.e. more than once) or if there was
	 *  some sort of error initializing this feature
	 */
	abstract bool startWritingMultipleStatements();
	
	/**
	 * Alias for startWritingMultipleStatements()
	 */
	alias startWritingMultipleStatements startMultiWrite;
	
	/**
	 * 
	 * Returns: true if the database instance in the write multiple statements mode,
	 * false otherwise
	 */
	abstract bool isWritingMultipleStatements();
	
	/**
	 * Alias for isWritingMultipleStatements()
	 */
	alias isWritingMultipleStatements isMultiWrite;
	
	///
	abstract Statement doPrepare(char[] sql);
	
	abstract SqlStringWriter buffer();
	
	abstract void buffer(SqlStringWriter);
	
	debug(DBITest) {
		abstract void doTests();
		
		void test()
		{
			try
			{
				doTests;
			}
			catch(DBIException ex)
			{
				Stdout.formatln("Caught DBIException: {}, DBI Code:{}, DB Code:{}, Sql: {}", ex.toString, DBIErrorCode.toString(ex.getErrorCode), ex.getSpecificCode, ex.getSql);
				throw ex;
			}
		}
	}
}

private class TestDatabase : Database {
	void connect (char[] params, char[] username = null, char[] password = null) {}
	void close () {}
}

debug(DBITest) {

	import DBIErrorCode = dbi.ErrorCode;
	import dbi.util.StringWriter;
	import tango.math.Math;
	import tango.time.Clock;
	
	class DBTest
	{		
		const static ColumnInfo[] columns = [
		   ColumnInfo("id", BindType.UInt, true, true, true),
		   ColumnInfo("UByte", BindType.UByte),
		   ColumnInfo("Byte", BindType.Byte),
		   ColumnInfo("UShort", BindType.UShort),
		   ColumnInfo("Short", BindType.Short),
		   ColumnInfo("UInt", BindType.UInt),
		   ColumnInfo("Int", BindType.Int),
		   ColumnInfo("ULong", BindType.ULong),
		   ColumnInfo("Long", BindType.Long),
		   ColumnInfo("Float", BindType.Float),
		   ColumnInfo("Double", BindType.Double),
		   ColumnInfo("String", BindType.String, true, false, false, 45),
		   ColumnInfo("Binary", BindType.Binary, false, false, false),
		   ColumnInfo("DateTime", BindType.DateTime),
		   ColumnInfo("Time", BindType.Time),
		];
		
		this(Database db)
		{
			this.db = db;
			this.writer = new SqlStringWriter;
			this.log = Log.lookup("dbi.DBTest");
		}
		
		Database db;
		SqlStringWriter writer;
		Logger log;
		
		void run()
		{
			setup;
			
			initData;
			insert;
			select;
			update;
			remove;
			testUtil;
			testMultiStatements;
			
			dbTests;
			teardown;
		}
		
		void setup()
		{
			log.trace("Dropping dbi_test");
			char[] drop_test = `DROP TABLE dbi_test`;
			log.trace("Executing: {}", excerpt(drop_test));
			db.query(drop_test);
			
			log.trace("Creating dbi_test");
			auto create_test = db.sqlGen.makeCreateSql("dbi_test", columns);
			log.trace("Executing: {}", excerpt(create_test));
			db.query(create_test);
			
			log.trace("Done setuping up dbi_test");
		}
		
		void teardown()
		{
			
		}
		
		struct Data
		{
			ubyte ub;
			byte b;
			ushort us;
			short s;
			uint ui;
			int i;
			ulong ul;
			long l;
			float f;
			double d;
			char[] str;
			void[] binary;
			DateTime dt;
			Time t;
		}
		
		Data data;
		
		void initData()
		{
			log.trace("Initializing data");
			data.ub = 1;
			data.b = -56;
			data.us = 15764;
			data.s = -5076;
			data.ui = 102389625;
			data.i = -400000;
			data.ul = 218356734346345475;
			data.l = -2358780732897345;
			data.f = 5.235689;
			data.d = 72523643.3458612319;
			data.str = "test test test test test";
			data.binary = cast(void[])[0,1,2,3,4,5,6,8,9,10];
			data.dt.date.year = 2008;
			data.dt.date.month = 1;
			data.dt.date.day = 1;
			data.dt.time.hours = 12;
			data.t = Clock.now;
		}
		
		void insert()
		{
 			auto sql = db.sqlGen.makeInsertSql(writer, "dbi_test",
				["UByte", "Byte", "UShort", "Short", "UInt", "Int",
				 "ULong", "Long", "Float", "Double",
				 "String", "Binary", "DateTime", "Time"]);
			auto st = db.prepare(sql);
			
			st.execute(data.ub,data.b,data.us,data.s,data.ui,data.i,
				data.ul,data.l,data.f,data.d,data.str,data.binary,data.dt,data.t);
			assert(st.affectedRows == 1);
			assert(db.lastInsertID == 1);
			
			
			db.insert("dbi_test",
				["UByte", "Byte", "UShort", "Short", "UInt", "Int",
				 "ULong", "Long", "Float", "Double",
				 "String", "Binary", "DateTime", "Time"],
				 data.ub,data.b,data.us,data.s,data.ui,data.i,
				data.ul,data.l,data.f,data.d,data.str,data.binary,data.dt,data.t);
			assert(db.affectedRows == 1);
			assert(db.lastInsertID == 2);
			
		}
		
		void update()
		{
			db.update("dbi_test",["UByte","Byte"],"WHERE id = ?",5,-7,1);
			db.update("dbi_test",["UByte","Byte"],"WHERE id = 2",5,-7);
			assert(db.affectedRows == 1);
			
			void doFetch()
			{
				ubyte ub; byte b;
				assert(db.fetchRow(&ub, &b));
				assert(ub == 5);
				assert(b == -7);
			}
			db.select("dbi_test",["UByte","Byte"],"WHERE id = 1");
			doFetch;
			db.select("dbi_test",["UByte","Byte"],"WHERE id = ?",2);
			doFetch;
		}
		
		void remove()
		{
			db.remove("dbi_test","WHERE id = 1");
			db.select("dbi_test",["id"],"WHERE 1");
			assert(db.rowCount == 1);
			db.remove("dbi_test","WHERE id = ?",2);
			db.select("dbi_test",["id"],"WHERE 1");
			assert(db.rowCount == 0);
		}
		
		void select()
		{
			auto list = db.sqlGen.makeFieldList(
				["id", "UByte", "Byte", "UShort", "Short", "UInt", "Int",
		    	 "ULong", "Long", "Float", "Double",
			     "String", "Binary", "DateTime", "Time"]);
			auto sql = "SELECT " ~ list ~ " FROM dbi_test WHERE 1";
			auto st = db.prepare(sql);
			assert(st);
			st.execute();
			Data dataCopy;
			uint id;
			
			void assertData() {
				assert(dataCopy.ub == data.ub);
				assert(dataCopy.b == data.b);
				assert(dataCopy.us == data.us);
				assert(dataCopy.s == data.s);
				assert(dataCopy.ui == data.ui);
				assert(dataCopy.i == data.i);
				assert(dataCopy.ul == data.ul,Integer.toString(dataCopy.ul) ~ " != " ~ Integer.toString(data.ul));
				assert(dataCopy.l == data.l);
				assert(abs(dataCopy.f - data.f) < 0.00001);
				assert(abs(dataCopy.d - data.d) < 0.0000001);
				assert(dataCopy.str == data.str);
				assert(dataCopy.binary == data.binary,
					cast(char[])dataCopy.binary ~ " != " ~ cast(char[])data.binary);
				assert(dataCopy.dt.date.year == data.dt.date.year);
				assert(dataCopy.dt.date.month == data.dt.date.month);
				assert(dataCopy.dt.date.day == data.dt.date.day);
				assert(dataCopy.dt.time.hours == data.dt.time.hours);
				assert(abs((dataCopy.t - data.t).ticks) < TimeSpan.seconds(1).ticks);
			}
			
			while(st.fetch(id, dataCopy.ub,dataCopy.b,dataCopy.us,dataCopy.s,dataCopy.ui,dataCopy.i,
					dataCopy.ul,dataCopy.l,dataCopy.f,dataCopy.d,dataCopy.str,dataCopy.binary,dataCopy.dt,dataCopy.t)) {
				assertData;
			}
			
			db.execute(sql);
			
			while(db.fetchRow(&id, &dataCopy.ub,&dataCopy.b,&dataCopy.us,&dataCopy.s,&dataCopy.ui,&dataCopy.i,
				&dataCopy.ul,&dataCopy.l,&dataCopy.f,&dataCopy.d,&dataCopy.str,&dataCopy.binary,&dataCopy.dt,&dataCopy.t)) {
				assertData;
			}
		}
		
		void testMultiStatements()
		{
			if(!db.enabled(DbiFeature.MultiStatements))
				return;
			
			
			
			/+
			char[] sql = db.sqlGen.makeInsertSql("dbi_test",
				["UByte", "Byte","String"]);
			sql ~= ";";
			sql ~= "SELECT UByte, Byte FROM dbi_test WHERE 1";
			db.query(sql,15,-15,"testMultiStatements");
			+/
			assert(db.startWritingMultipleStatements);
			assert(db.isWritingMultipleStatements);
			db.initInsert("dbi_test",
				["UByte", "Byte","String"]);
			db.setParams(15,-15,"testMultiStatements");
			db.initSelect("dbi_test",["UByte", "Byte"],"WHERE 1",false);
			db.doQuery;
			assert(!db.validResult);
			assert(db.affectedRows == 1);
			assert(db.moreResults);
			assert(db.nextResult);
			assert(db.rowCount == 1);
			ubyte ub; byte b;
			assert(db.fetchRow(&ub, &b));
			assert(ub == 15);
			assert(b == -15);
			assert(!db.fetchRow(&ub, &b));
			assert(!db.nextResult);
			assert(!db.moreResults);
		}
		
		void testUtil()
		{
			log.info("Escaped string: {}",db.escapeString(`"Hello \'world\'!"`));
		}
		
		/+
		
		void testMetadata()
		{
			assert(db.hasTable("dbi_test"));
			auto ti = db.getTableInfo("dbi_test"); 
			assert(ti);
			assert(ti.length == 6);
			
			ColumnInfo[char[]] fNames;
			foreach(col; ti)
				fNames[col.name] = col;
			
			auto pID = "id" in fNames;
			assert(pID);
			assert(pID.primaryKey);
			assert("name" in fNames);
			assert("binary" in fNames);
			assert("dateofbirth" in fNames);
			assert("i" in fNames);
			assert("f" in fNames);
		}
		+/
		
		void dbTests()
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

	s1("dbi.Database:");
	TestDatabase db;

	s2("getKeywords");
	char[][char[]] keywords = db.getKeywords("dbname=hi;host=local;");
	assert (keywords["dbname"] == "hi");
	assert (keywords["host"] == "local");
}
}