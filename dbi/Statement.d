/**
 * Authors: The D DBI project
 *
 * Version: 0.2.4
 *
 * Copyright: BSD license
 */
module dbi.Statement;

version (Ares) {
	private static import std.regexp;
	debug (UnitTest) private import std.io.Console;
} else {
	private static import std.string;
	debug (UnitTest) private import std.stdio;
}
private import dbi.Database, dbi.Result;

/**
 * A prepared SQL statement.
 *
 * Bugs:
 *	The statement is stored but not prepared.
 *
 *	The index version of bind ignores its first parameter.
 *
 *	The two forms of bind cannot be used at the same time.
 *
 * Todo:
 *	make execute/query("10", "20", 30); work (variable arguments for binding to ?, ?, ?, etc...)
 */
final class Statement {
	/**
	 * Make a new instance of Statement.
	 *
	 * Params:
	 *	database = The database connection to use.
	 *	sql = The SQL code to prepare.
	 */
	this (Database database, char[] sql) {
		this.database = database;
		this.sql = sql;
	}

	/**
	 * Bind a _value to the next "?".
	 *
	 * Params:
	 *	index = Currently ignored.  This is a bug.
	 *	value = The _value to _bind.
	 */
	void bind (size_t index, char[] value) {
		binds ~= escape(value);
	}

	/**
	 * Bind a _value to a ":name:".
	 *
	 * Params:
	 *	fn = The name to _bind value to.
	 *	value = The _value to _bind.
	 */
	void bind (char[] fn, char[] value) {
		bindsFNs ~= fn;
		binds ~= escape(value);
	}

	/**
	 * Execute a SQL statement that returns no results.
	 */
	void execute () {
		database.execute(getSql());
	}

	/**
	 * Query the database.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 */
	Result query () {
		return database.query(getSql());
	}

	private:
	Database database;
	char[] sql;
	char[][] binds;
	char[][] bindsFNs;

	/**
	 * Escape a SQL statement.
	 *
	 * Params:
	 *	string = An unescaped SQL statement.
	 *
	 * Returns:
	 *	The escaped form of string.
	 */
	char[] escape (char[] string) {
		version (Ares) {
			return std.regexp.sub(string, "'", "''");
		} else {
			return std.string.replace(string, "'", "''");
		}
	}

	/**
	 * Replace every "?" in the current SQL statement with its bound value.
	 *
	 * Returns:
	 *	The current SQL statement with all occurences of "?" replaced.
	 *
	 * Todo:
	 *	Raise an exception if binds.length != count(sql, "?")
	 */
	char[] getSqlByQM () {
		char[] result = sql;
		int qmIdx = 0, qmCount = 0;

		void replace () {
			result = result[0 .. qmIdx] ~ "'" ~ binds[qmCount] ~ "'" ~ result[qmIdx + 1 .. result.length];
				qmCount++;
		}

		version (Ares) {
			while((qmIdx = std.regexp.find(result, "\\u003F")) != size_t.max) {
				replace();
			}
		} else {
			while ((qmIdx = std.string.find(result, "?")) != -1) {
				replace();
			}
		}
		return result;
	}

	/**
	 * Replace every ":name:" in the current SQL statement with its bound value.
	 *
	 * Returns:
	 *	The current SQL statement with all occurences of ":name:" replaced.
	 *
	 * Todo:
	 *	Raise an exception if binds.length != (count(sql, ":") * 2)
	 */
	char[] getSqlByFN () {
		char[] result = sql;
		ptrdiff_t begIdx = 0, endIdx = 0;
		version (Ares) {
			while ((begIdx = std.regexp.find(result, ":")) != -1 && (endIdx = std.regexp.find(result[begIdx + 1 .. length], ":")) != -1) {
				result = result[0 .. begIdx] ~ "'" ~ getBoundValue(result[begIdx + 1.. begIdx + endIdx + 1])~ "'" ~ result[begIdx + endIdx + 2 .. length];
			}
		} else {
			while ((begIdx = std.string.find(result, ":")) != -1 && (endIdx = std.string.find(result[begIdx + 1 .. length], ":")) != -1) {
				result = result[0 .. begIdx] ~ "'" ~ getBoundValue(result[begIdx + 1.. begIdx + endIdx + 1])~ "'" ~ result[begIdx + endIdx + 2 .. length];
			}
		}
		return result;
	}

	/**
	 * Replace all variables with their bound values.
	 *
	 * Returns:
	 *	The current SQL statement with all occurences of variables replaced.
	 */
	char[] getSql () {
		version (Ares) {
			if (std.regexp.find(sql, "\\u003F") != size_t.max) {
				return getSqlByQM();
			} else if (std.regexp.find(sql, ":") != size_t.max) {
				return getSqlByFN();
			} else {
				return sql;
			}
		} else {
			if (std.string.find(sql, "?") != -1) {
				return getSqlByQM();
			} else if (std.string.find(sql, ":") != -1) {
				return getSqlByFN();
			} else {
				return sql;
			}
		}
	}

	/**
	 * Get the value bound to a ":name:".
	 *
	 * Params:
	 *	fn = The ":name:" to return the bound value of.
	 *
	 * Returns:
	 *	The bound value of fn.
	 */
	char[] getBoundValue (char[] fn) {
		for (ptrdiff_t idx = 0; idx < bindsFNs.length; idx++) {
			if (bindsFNs[idx] == fn) {
				return binds[idx];
			}
		}
		return null;
	}
}

unittest {
	version (Ares) {
		void s1 (char[] s) {
			Cout("" ~ s ~ "\n");
		}

		void s2 (char[] s) {
			Cout("   ..." ~ s ~ "\n");
		}
	} else {
		void s1 (char[] s) {
			writefln("%s", s);
		}

		void s2 (char[] s) {
			writefln("   ...%s", s);
		}
	}

	s1("dbi.Statement:");
	Statement stmt = new Statement(null, "SELECT * FROM people");
	char[] resultingSql = "SELECT * FROM people WHERE id = '10' OR name LIKE 'John Mc''Donald'";

	s2("escape");
	assert(stmt.escape("John Mc'Donald") == "John Mc''Donald");

	s2("simple sql");
	stmt = new Statement(null, "SELECT * FROM people");
	assert(stmt.getSql() == "SELECT * FROM people");

	s2("bind by '?'");
	stmt = new Statement(null, "SELECT * FROM people WHERE id = ? OR name LIKE ?");
	stmt.bind(1, "10");
	stmt.bind(2, "John Mc'Donald");
	assert(stmt.getSql() == resultingSql);

	/+
	s2("bind by '?' sent to getSql via variable arguments");
	stmt = new Statement("SELECT * FROM people WHERE id = ? OR name LIKE ?");
	assert(stmt.getSql("10", "John Mc'Donald") == resultingSql);
	+/

	s2("bind by ':fieldname:'");
	stmt = new Statement(null, "SELECT * FROM people WHERE id = :id: OR name LIKE :name:");
	stmt.bind("id", "10");
	stmt.bind("name", "John Mc'Donald");
	assert(stmt.getBoundValue("name") == "John Mc''Donald");
	assert(stmt.getSql() == resultingSql);
}