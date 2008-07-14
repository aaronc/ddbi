/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.Database;

private static import tango.text.Util;
private static import tango.io.Stdout;
private import dbi.DBIException;
public import dbi.SqlGen, dbi.Statement, dbi.Metadata;

debug(UnitTest) import tango.io.Stdout;

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
abstract class Database {
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
	
	abstract void execute(char[] sql);
	abstract void execute(char[] sql, BindType[] bindTypes, void*[] ptrs);
	
	abstract IStatement prepare(char[] sql);
	abstract IStatement virtualPrepare(char[] sql);
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
	
    static this()
    {
    	sqlGen = new SqlGenerator;
    }
    private static SqlGenerator sqlGen;
	
	SqlGenerator getSqlGenerator()
	{
		return sqlGen;
	}
}

private class TestDatabase : Database {
	void connect (char[] params, char[] username = null, char[] password = null) {}
	void close () {}
}

debug(UnitTest) {

	abstract class DBTest
	{
		this(Database db, bool virtual = false)
		{
			this.db = db;
			this.virtual = virtual;
			
			bind.length = 3;
			bind[0] = &id;
			bind[1] = &name;
			bind[2] = &dateofbirth;
		}
		
		void run()
		{
			setup;
			test1;
			test2;
			test3;
			teardown;
		}
		
		abstract void setup();
		abstract void teardown();
		
		
		BindType[] resTypes =
		[
		 	BindType.UInt,
		 	BindType.String,
		 	BindType.Time
		];
		
		Database db;
		bool virtual;
		
		uint id;
		char[] name;
		Time dateofbirth;
		
		
		void*[] bind;
		
		IStatement prepare(char[] sql)
		{
			if(!virtual)
				return db.prepare(sql);
			else
				return db.virtualPrepare(sql);
		}
		
		void test1()
		{
			auto sqlGen = db.getSqlGenerator;
			auto sql = sqlGen.makeInsertSql("test", ["name", "dateofbirth"]);
			auto st = db.prepare(sql);
			
			Stdout.formatln("Prepared:test1 - {}", sql);
			
			name = "test";
			DateTime dt;
			dt.date.year = 2008;
			dt.date.month = 1;
			dt.date.day = 1;
			dateofbirth = Clock.fromDate(dt);

			BindType[] pTypes = [BindType.String, BindType.Time];
			
			void*[] pBind;
			pBind ~= &name;
			pBind ~= &dateofbirth;
			
			st.setParamTypes(pTypes);
			Stdout.formatln("setParamTypes:test1");
			
			st.execute(pBind);
			Stdout.formatln("Completed:test1");			
		}
		
		void test2()
		{
			auto st2 = db.prepare("SELECT * FROM test WHERE 1");
					
			assert(st2);
			assert(st2.getParamCount == 0);
			st2.execute();
			auto metadata = st2.getResultMetadata();
			foreach(f; metadata)
			{
				Stdout.formatln("Name:{}, Type:{}", f.name, f.type);
			}
			
			st2.setResultTypes(resTypes);
			
			st2.execute;
			assert(st2.fetch(bind));
			Stdout.formatln("id:{},name:{},dateofbirth:{}",id,name,dateofbirth.ticks);
			assert(!st2.fetch(bind));
		}
		
		void test3()
		{
			auto st3 = db.prepare("SELECT * FROM test WHERE id = \?");
			
			assert(st3);
			
			BindType[] paramTypes = [BindType.UShort];
			
			void*[] pBind;
			ushort usID = 1;
			st3.setParamTypes(paramTypes);
			st3.setResultTypes(resTypes);
			pBind ~= &usID;
			st3.execute(pBind);
			assert(st3.fetch(bind));
			Stdout.formatln("id:{},name:{},dateofbirth:{}",id,name,dateofbirth.ticks);
			st3.reset;
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