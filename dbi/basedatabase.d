/**
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.BaseDatabase;

private import std.string;
private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;

/**
 * Base Database implementation that it is suggested that other DBD's
 * inherit from. This defines a few functions that are DBD independent
 * such as Database.queryFetchOne and Database.queryFetchAll. For
 * all other functions a DBIException is thrown with the message
 * content "Not impemented."
 *
 * New DBD classes should inherit from BaseDatabase, not directly from
 * the Database interface.
 *
 * See_Also:
 *	Database
 */
class BaseDatabase : Database {
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
	 * Throws:
	 *	DBIException if the function isn't overridden.
	 */
	override void connect (char[] conn, char[] user = null, char[] passwd = null) {
		throw new DBIException("Not implemented.");
	}

	/**
	 * Throws:
	 *	DBIException if the function isn't overridden.
	 */
	override void close () {
		throw new DBIException("Not implemented.");
	}

	/**
	 * Throws:
	 *	DBIException if the function isn't overridden.
	 */
	override void execute (char[] sql) {
		throw new DBIException("Not implemented.");
	}

	/**
	 *
	 */
	override Statement prepare (char[] sql) {
		return new Statement(cast(Database)this, sql);
	}

	/**
	 * Throws:
	 *	DBIException if the function isn't overridden.
	 */
	override Result query (char[] sql) {
		throw new DBIException("Not implemented.");
	}

	/**
	 * 
	 */
	final override Row queryFetchOne (char[] sql) {
		Result res = query(sql);
		if (res is null) {
			return null;
		}
		Row row = res.fetchRow();
		res.finish();
		return row;
	}

	/**
	 *
	 */
	final override Row[] queryFetchAll (char[] sql) {
		Result res = query(sql);
		if (res is null) {
			return null;
		}
		Row[] rows = res.fetchAll();
		res.finish();
		return rows;
	}

	/**
	 * Throws:
	 *	DBIException if the function isn't overridden.
	 */
	deprecated override int getErrorCode () {
		throw new DBIException("Not implemented.");
	}

	/**
	 * Throws:
	 *	DBIException if the function isn't overridden.
	 */
	deprecated override char[] getErrorMessage () {
		throw new DBIException("Not implemented.");
	}

	/**
	 * Takes a string and returns keywords and their values in a character array.
	 */
	final protected char[][char[]] getKeywords (char[] s) {
		char[][char[]] keywords;
		char[][] groups = std.string.split(s, ";");
		foreach (char[] group; groups) {
			if (group == "") {
				continue;
			}
			char[][] vals = std.string.split(group, "=");
			keywords[vals[0]] = vals[1];
		}
		return keywords;
	}
}

unittest {
	void s1 (char[] s) {
		printf("%.*s\n", s);
	}
	void s2 (char[] s) {
		printf("   ...%.*s\n", s);
	}

	s1("dbi.BaseDatabase");
	BaseDatabase db = new BaseDatabase();

	s2("getKeywords");
	char[][char[]] keywords = db.getKeywords("dbname=hi;host=local;");
	assert(keywords["dbname"] == "hi");
	assert(keywords["host"] == "local");
  }