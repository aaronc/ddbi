﻿/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.Database;

private static import tango.text.Util;
private static import tango.io.Stdout;
private import dbi.DBIException;
public import dbi.SqlGen, dbi.PreparedStatement, dbi.Metadata;

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
	 * Connect to a database.
	 *
	 * Note that each DBD treats the parameters a slightly different way, so
	 * this is currently the only core function that cannot have its code
	 * reused for another DBD.
	 *
	 * Params:
	 *	params = A string describing the connection parameters.
	 *             documentation for the DBD before
	 *	username = The _username to _connect with.  Some DBDs ignore this.
	 *	password = The _password to _connect with.  Some DBDs ignore this.
	 */
	abstract void connect (char[] params, char[] username = null, char[] password = null);

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
	abstract void close ();
	
	IPreparedStatement prepare(char[] sql);
	IPreparedStatement virtualPrepare(char[] sql);
	void beginTransact();
	void rollback();
	void commit();

	/**
	 * Escape a _string using the database's native method, if possible.
	 *
	 * Params:
	 *	string = The _string to escape,
	 *
	 * Returns:
	 *	The escaped _string.
	 */
	char[] escape (char[] string)
	{
		char[] result;
		size_t count = 0;

		// Maximum length needed if every char is to be quoted
		result.length = string.length * 2;

		for (size_t i = 0; i < string.length; i++) {
			switch (string[i]) {
				case '"':
				case '\'':
				case '\\':
					result[count++] = '\\';
					break;
				default:
					break;
			}
			result[count++] = string[i];
		}

		result.length = count;
		return result;
	}
  
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
	final protected char[][char[]] getKeywords (char[] string) {
		char[][char[]] keywords;
		foreach (char[] group; tango.text.Util.delimit(string, ";")) {
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