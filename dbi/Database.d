﻿/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.Database;

private static import tango.text.Util;
private static import tango.io.Stdout;
private import dbi.DBIException;
public import dbi.SqlGen, dbi.Statement, dbi.Metadata, dbi.Result;

debug(DBITest) public import tango.io.Stdout;

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
		close();
	}

	/**
	 * Close the current connection to the database.
	 */
	abstract void close();	
	
	abstract void initQuery(in char[] sql);
	abstract bool doQuery();
	
	abstract void setParam(inout bool);
	abstract void setParam(inout ubyte);
	abstract void setParam(inout byte);
	abstract void setParam(inout ushort);
	abstract void setParam(inout short);
	abstract void setParam(inout uint);
	abstract void setParam(inout int);
	abstract void setParam(inout ulong);
	abstract void setParam(inout long);
	abstract void setParam(inout float);
	abstract void setParam(inout double);
	abstract void setParam(inout char[]);
	abstract void setParam(inout ubyte[]);
	abstract void setParam(inout Time);
	abstract void setParam(inout DateTime);
	
	bool query(Types)(in char[] sql, Types bind)
	{
		initQuery(sql);
		
		uint idx = 0;
		foreach(Index, Type; BindTypes)
		{
			static if(is(Type : BindInfo))
	    	{
				auto bindInfo = cast(Binder)bind[Index];
				
				auto ptrs = bindInfo.ptrs;
	    		foreach(i, type; bindInfo.types)
	    		{
	    			switch(type)
	    			{
	    			case BindType.Bool:
	    				bool* ptr = cast(bool*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.Byte:
	    				byte* ptr = cast(byte*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.Short:
	    				short* ptr = cast(short*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.Int:
	    				int* ptr = cast(int*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.Long:
	    				long* ptr = cast(long*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.UByte:
	    				ubyte* ptr = cast(ubyte*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.UShort:
	    				ushort* ptr = cast(ushort*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.UInt:
	    				uint* ptr = cast(uint*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.ULong:
	    				ulong* ptr = cast(ulong*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.Float:
	    				float* ptr = cast(float*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.Double:
	    				double* ptr = cast(double*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.String:
	    				char[]* ptr = cast(char[]*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.Binary:
	    				ubyte[]* ptr = cast(ubyte[]*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.Time:
	    				Time* ptr = cast(T.Time*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.DateTime:
	    				DateTime* ptr = cast(T.DateTime*)ptrs[i];
	    				setParam(*ptr, idx);
	    				break;
	    			case BindType.Null:
	    			}
	    			++idx;
	    		}
	    	}
	    	else {
	    		setParam(bind[Index], idx);
	    		++idx;
	    	}
		}
		
		return doQuery();
	}
		
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
			return *pSt;
		}
	}
	//abstract char[] writeHexString(in ubyte[] binary, char[] dst = null);
	//abstract char[] writeDateTime(DateTime dateTime, char[] dst = null);
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
				//Log.getRootLogger.addAppender(new ConsoleAppender);
				
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
	
	class DBTest
	{
		static class Test
		{
			this()
			{
				bind.length = 6;
				bind[0] = &id;
				bind[1] = &name;
				bind[2] = &dateofbirth;
				bind[3] = &binary;
				bind[4] = &i;
				bind[5] = &f;
			}
			
			uint id;
			char[] name;
			Time dateofbirth;
			ubyte[] binary;
			long i;
			double f;
			
			void*[] bind;
			
			static BindType[] resTypes =
			[
			 	BindType.UInt,
			 	BindType.String,
			 	BindType.Time,
			 	BindType.Binary,
			 	BindType.Long,
			 	BindType.Double
			];
		}
		
		const static ColumnInfo[] columns = [
		   ColumnInfo("id", BindType.UInt, true, true, true),
		   ColumnInfo("name", BindType.String, true, false, false, 45),
		   ColumnInfo("binary", BindType.Binary, false, false, false),
		   ColumnInfo("dateofbirth", BindType.DateTime),
		   ColumnInfo("i", BindType.Int),
		   ColumnInfo("f", BindType.Double)
		];
		
		this(Database db, bool virtual = false)
		{
			this.db = db;
			this.virtual = virtual;
			
			t1 = new Test;
		}
		
		void run()
		{
			setup;
			test1;
			test2;
			//test3;
			testMetadata;
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
		
		Database db;
		bool virtual;
		
		Test t1;
		
		Statement prepare(char[] sql)
		{
			return db.prepare(sql);
		}
		
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
		
		void test1()
		{
			auto sqlGen = db.getSqlGenerator;
			auto sql = sqlGen.makeInsertSql("dbi_test", ["name", "dateofbirth", "binary", "i", "f"]);
			auto st = prepare(sql);
			
			Stdout.formatln("Prepared:test1 - {}", sql);
					
			t1.name = "test test test";
			DateTime dt;
			dt.date.year = 2008;
			dt.date.month = 1;
			dt.date.day = 1;
			t1.dateofbirth = Clock.fromDate(dt);
			ulong x = 0x57a60e9fe4321b0;
			t1.binary = (cast(ubyte*)&x)[0 .. 8].dup;
			t1.i = 5798637;
			t1.f = 3.14159265;

			BindType[] pTypes = [BindType.String, BindType.Time, BindType.Binary, BindType.Long, BindType.Double];
			
			void*[] pBind;
			pBind ~= &t1.name;
			pBind ~= &t1.dateofbirth;
			pBind ~= &t1.binary;
			pBind ~= &t1.i;
			pBind ~= &t1.f;
			
			st.setParamTypes(pTypes);
			Stdout.formatln("setParamTypes:test1");
			
			st.doExecute(pBind);
			t1.id = st.getLastInsertID;
			assert(t1.id == 1);
			
			Stdout.formatln("Completed:test1");
		}		
	
		void test2()
		{
			auto sqlGen = db.getSqlGenerator;
			auto list = sqlGen.makeFieldList(["id", "name", "dateofbirth", "binary", "i", "f"]);
			auto sql = "SELECT " ~ list ~ " FROM dbi_test WHERE id = ?";
			
			auto st2 = prepare(sql);
			
			assert(st2);
			assert(st2.getParamCount == 1);
			
			BindType[] paramTypes = [BindType.UShort];
			
			void*[] pBind;
			ushort usID = 1;
			
			st2.setParamTypes(paramTypes);
			st2.setResultTypes(Test.resTypes);
			
			pBind ~= &usID;
			
			st2.doExecute(pBind);
			
			
			auto metadata = st2.getResultMetadata();
			foreach(f; metadata)
			{
				Stdout.formatln("Name:{}, Type:{}", f.name, f.type);
			}
			
			auto t2 = new Test;
			
			assert(st2.fetch(t2.bind));
			
			assert(t2.id == t1.id);
			assert(t2.name == t1.name);
			assert(t2.dateofbirth == t1.dateofbirth);
			assert(t2.binary == t1.binary,
				sqlGen.createBinaryString(t1.binary) ~ " " ~ sqlGen.createBinaryString(t2.binary));
			assert(t2.i == t1.i);
			assert(abs(t2.f - t1.f) < 1e9);
			assert(!st2.fetch(t2.bind));
			
			st2.reset;
		}
		
		void test3()
		{
			auto sql = db.sqlGen.makeAddColumnSql("dbi_test", ColumnInfo("added_column", BindType.String));
			Stdout.formatln("executing: {}", sql);
			db.execute(sql);
		}
		
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