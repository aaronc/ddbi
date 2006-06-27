/**
 * Copyright: LGPL
 */
module dbi.Statement;

private import std.string;
private import dbi.Database, dbi.Result;

/**
 * SQL statement
 *
 * Todo:
 *	make execute/query("10", "20", 30); work (variable arguments for binding to ?, ?, ?, etc...)
 */
class Statement {
	/**
	 *
	 */
	this (Database db, char[] sql) {
		this.db = db;
		this.sql = sql;
	}

	/**
	 *
	 */
	void bind (uint idx, char[] value) {
		binds ~= escape(value);
	}

	/**
	 *
	 */
	void bind (char[] fn, char[] value) {
		bindsFNs ~= fn;
		binds ~= escape(value);
	}

	/**
	 *
	 */
	char[] escape (char[] str) {
		return replace(str, "'", "''");
	}

	/**
	 *
	 */
	void execute () {
		db.execute(getSql());
	}

	/**
	 *
	 */
	Result query () {
		return db.query(getSql());
	}

	private:
	Database db;
	char[] sql;
	char[][] binds;
	char[][] bindsFNs;

	/**
	 * Build SQL by replacing ?'s in sequential order
	 *
	 * Todo:
	 *	Raise an exception if binds.length != count(sql, "?")
	 */
	char[] getSqlByQM () {
		char[] result = sql;
		int qmIdx = 0, qmCount = 0;
		while ((qmIdx = find(result, "?")) != -1) {
			result = result[0 .. qmIdx] ~ "'" ~ binds[qmCount] ~ "'" ~ result[qmIdx + 1 .. result.length];
			qmCount += 1;
		}
		return result;
	}

	/**
	 * Build SQL by replacing :fieldname: with values in binds
	 *
	 * Todo:
	 *	Raise an exception if binds.length != (count(sql, ":") * 2)
	 */
	char[] getSqlByFN () {
		char[] result = sql;
		int begIdx = 0, endIdx = 0;
		while ((begIdx = find(result, ":")) != -1 && (endIdx = find(result[begIdx + 1 .. result.length], ":")) != -1) {
			result = result[0 .. begIdx] ~ "'" ~ getBoundValue(result[begIdx + 1.. begIdx + endIdx + 1])~ "'" ~ result[begIdx + endIdx + 2 .. result.length];
		}
		return result;
	}

	/**
	 *
	 */
	char[] getSql () {
		if (count(sql, "?") > 0) {
			return getSqlByQM();
		} else if (count(sql, ":") > 0) {
			return getSqlByFN();
		}
		return sql;
	}

	/**
	 *
	 */
	char[] getBoundValue (char[] fn) {
		for (int idx = 0; idx < bindsFNs.length; idx++) {
			if (bindsFNs[idx] == fn) {
				return binds[idx];
			}
		}
		return null;
	}
}

unittest {
	void s1 (char[] s) {
		printf("%.*s\n", s);
	}
	void s2 (char[] s) {
		printf("   ...%.*s\n", s);
	}

	s1("dbi.statement:");
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