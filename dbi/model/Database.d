/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.model.Database;

private static import tango.text.Util;
private static import tango.io.Stdout;
public import dbi.Exception;
public import dbi.util.SqlGen, dbi.model.Statement, dbi.model.Metadata, dbi.model.Result;

debug(DBITest) public import tango.io.Stdout;

enum DbiFeature
{
    MultiStatements 
}


/**
 * The database interface that all DBDs must inherit from.
 *
 * Database only provides a core set of functionality.  Many DBDs have functions
 * that are specific to themselves, as they wouldn't make sense in any many other
 * databases.  Please reference the documentation for the DBD you will be using to
 * discover these functions.
 *
 * See_Also:
 *	The database class for the DBD you are using.
 */
abstract class Database : Result, IStatementProvider {
	/**
	 * A destructor that attempts to force the the release of of all
	 * database connections and similar things.
	 *
	 * The current D garbage collector doesn't always call destructors,
	 * so it is HIGHLY recommended that you close connections manually.
	 */
	~this () {
		/+foreach(key, st; cachedStatements)
			st.close;+/
		close();
	}

   /**
     * Returns true if the given feature has been enabled in
     * this Database instance.
     */
   bool enabled(DbiFeature feature);
	
	/**
	 * Close the current connection to the database.
	 */
	abstract void close();	
	
	abstract void initQuery(in char[] sql, bool haveParams);
	abstract bool doQuery();
	
	abstract void setParam(bool);
	abstract void setParam(ubyte);
	abstract void setParam(byte);
	abstract void setParam(ushort);
	abstract void setParam(short);
	abstract void setParam(uint);
	abstract void setParam(int);
	abstract void setParam(ulong);
	abstract void setParam(long);
	abstract void setParam(float);
	abstract void setParam(double);
	abstract void setParam(char[]);
	abstract void setParam(ubyte[]);
	abstract void setParam(Time);
	abstract void setParam(DateTime);
	
	private void setParams(Types...)(Types bind)
	{
		foreach(Index, Type; Types)
		{
			static if(is(Type : BindInfo))
	    	{
				auto bindInfo = cast(BindInfo)bind[Index];
				
				auto ptrs = bindInfo.ptrs;
	    		foreach(i, type; bindInfo.types)
	    		{
	    			switch(type)
	    			{
	    			case BindType.Bool:
	    				bool* ptr = cast(bool*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Byte:
	    				byte* ptr = cast(byte*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Short:
	    				short* ptr = cast(short*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Int:
	    				int* ptr = cast(int*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Long:
	    				long* ptr = cast(long*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.UByte:
	    				ubyte* ptr = cast(ubyte*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.UShort:
	    				ushort* ptr = cast(ushort*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.UInt:
	    				uint* ptr = cast(uint*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.ULong:
	    				ulong* ptr = cast(ulong*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Float:
	    				float* ptr = cast(float*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Double:
	    				double* ptr = cast(double*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.String:
	    				char[]* ptr = cast(char[]*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Binary:
	    				ubyte[]* ptr = cast(ubyte[]*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Time:
	    				Time* ptr = cast(Time*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.DateTime:
	    				DateTime* ptr = cast(DateTime*)ptrs[i];
	    				setParam(*ptr);
	    				break;
	    			case BindType.Null:
	    			}
	    		}
	    	}
			else static if(is(Type : void[])) {
				setParam(cast(ubyte[])bind[Index]);
			}
	    	else {
	    		setParam(bind[Index]);
	    	}
		}
	}
	
	bool query(Types...)(in char[] sql, Types bind)
	{
		static if(Types.length) {
			initQuery(sql, true);
			setParams(bind);			
		}
		else initQuery(sql, false);
	
		return doQuery();
	}
	
	abstract void initInsert(char[] tablename, char[][] fields);
	abstract void initUpdate(char[] tablename, char[][] fields, char[] where);
	abstract void initSelect(char[] tablename, char[][] fields, char[] where, bool haveParams);
	abstract void initRemove(char[] tablename, char[] where, bool haveParams);
	bool insert(Types...)(char[] tablename, char[][] fields, Types bind)
	{
		initInsert(tablename, fields);
		setParams(bind);			
		return doQuery();
	}
	
	bool update(Types...)(char[] tablename, char[][] fields, char[] where, Types bind)
	{
		initUpdate(tablename, fields, where);
		setParams(bind);
		return doQuery();
	}
	
	bool select(Types...)(char[] tablename, char[][] fields, char[] where, Types bind)
	{
		bool haveParams = Types.length ? true : false;
		initSelect(tablename, fields, where, haveParams);
		setParams(bind);
		return doQuery();
	}
	
	bool remove(Types...)(char[] tablename, char[] where, Types bind)
	{
		bool haveParams = Types.length ? true : false;
		initRemove(tablename, where, haveParams);
		setParams(bind);
		return doQuery();
	}
	
	alias query execute;
	
	abstract ulong lastInsertID();
		
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
	private Statement[char[]] cachedStatements;
	
	abstract Statement doPrepare(char[] sql);
	
	void uncacheStatement(Statement st)
	{
		uncacheStatement(st.sql);
	}
	
	void uncacheStatement(char[] sql)
	{
		auto pSt = sql in cachedStatements;
		if(pSt) {
			cachedStatements.remove(sql);
		}
	}
	abstract char[] escapeString(in char[] str, char[] dst = null);
	
	abstract void beginTransact();
	abstract void rollback();
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
	
	abstract bool hasTable(char[] tablename);
	abstract ColumnInfo[] getTableInfo(char[] tablename);
	abstract SqlGenerator getSqlGenerator();
	alias getSqlGenerator sqlGen;
	
	alias Statement StatementT;
	
	/**
	 * 
	 * Returns: The database type for this instance (i.e. Mysql, Sqlite, Postgresql, etc.)
	 */
	abstract char[] type();
	
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
		}
		
		Database db;
		
		void run()
		{
			setup;
			
			initData;
			insert;
			select;
			update;
			remove;
			testMultiStatements;
			
			dbTests;
			teardown;
		}
		
		void setup()
		{
			char[] drop_test = db.sqlGen.makeDropSql("dbi_test");
			Stdout.formatln("executing: {}", drop_test);
			db.query(drop_test);
			
			auto create_test = db.sqlGen.makeCreateSql("dbi_test", columns);
			Stdout.formatln("executing: {}", create_test);
			db.query(create_test);
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
			auto sql = db.sqlGen.makeInsertSql("dbi_test",
				["UByte", "Byte", "UShort", "Short", "UInt", "Int",
				 "ULong", "Long", "Float", "Double",
				 "String", "Binary", "DateTime", "Time"]);
			auto st = db.prepare(sql);
			
			st.execute(data.ub,data.b,data.us,data.s,data.ui,data.i,
				data.ul,data.l,data.f,data.d,data.str,data.binary,data.dt,data.t);
			assert(st.affectedRows == 1);
			assert(db.lastInsertID == 1);
			
			
			assert(db.insert("dbi_test",
				["UByte", "Byte", "UShort", "Short", "UInt", "Int",
				 "ULong", "Long", "Float", "Double",
				 "String", "Binary", "DateTime", "Time"],
				 data.ub,data.b,data.us,data.s,data.ui,data.i,
				data.ul,data.l,data.f,data.d,data.str,data.binary,data.dt,data.t));
			assert(db.affectedRows == 1);
			assert(db.lastInsertID == 2);
			
		}
		
		void update()
		{
			assert(db.update("dbi_test",["UByte","Byte"],"WHERE id = ?",5,-7,1));
			assert(db.update("dbi_test",["UByte","Byte"],"WHERE id = 2",5,-7));
			assert(db.affectedRows == 1);
			
			void doFetch()
			{
				ubyte ub; byte b;
				assert(db.fetchRow(ub, b));
				assert(ub == 5);
				assert(b == -7);
			}
			assert(db.select("dbi_test",["UByte","Byte"],"WHERE id = 1"));
			doFetch;
			assert(db.select("dbi_test",["UByte","Byte"],"WHERE id = ?",2));
			doFetch;
		}
		
		void remove()
		{
			assert(db.remove("dbi_test","WHERE id = 1"));
			assert(db.select("dbi_test",["id"],"WHERE 1"));
			assert(db.rowCount == 1);
			assert(db.remove("dbi_test","WHERE id = ?",2));
			assert(db.select("dbi_test",["id"],"WHERE 1"));
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
				assert(dataCopy.ul == data.ul);
				assert(dataCopy.l == data.l);
				assert(abs(dataCopy.f - data.f) < 0.00001);
				assert(abs(dataCopy.d - data.d) < 0.0000001);
				assert(dataCopy.str == data.str);
				assert(dataCopy.binary == data.binary);
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
			
			assert(db.execute(sql));
			
			while(db.fetchRow(id, dataCopy.ub,dataCopy.b,dataCopy.us,dataCopy.s,dataCopy.ui,dataCopy.i,
				dataCopy.ul,dataCopy.l,dataCopy.f,dataCopy.d,dataCopy.str,dataCopy.binary,dataCopy.dt,dataCopy.t)) {
				assertData;
			}
		}
		
		void testMultiStatements()
		{
			if(!db.enabled(DbiFeature.MultiStatements))
				return;
			
			char[] sql = db.sqlGen.makeInsertSql("dbi_test",
				["UByte", "Byte","String"]);
			sql ~= ";";
			sql ~= "SELECT UByte, Byte FROM dbi_test WHERE 1";
			assert(db.query(sql,15,-15,"testMultiStatements"));
			assert(!db.validResult);
			assert(db.affectedRows == 1);
			assert(db.moreResults);
			assert(db.nextResult);
			assert(db.rowCount == 1);
			ubyte ub; byte b;
			assert(db.fetchRow(ub, b));
			assert(ub == 15);
			assert(b == -15);
			assert(!db.fetchRow(ub, b));
			assert(!db.nextResult);
			assert(!db.moreResults);
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