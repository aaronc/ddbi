/**
 * Authors: The D DBI project
 *
 * Version: 0.2.4
 *
 * Copyright: BSD license
 */
module dbi.pg.PgResult;

version (Ares) {
	private static import std.regexp;
	private import util.string : asString = toString;
} else {
	private import std.string : strip, asString = toString;
}
private import dbi.Result, dbi.Row;
private import dbi.pg.imp;

/**
 * Manage a result set from a PostgreSQL database query.
 *
 * See_Also:
 *	Result is the interface of which this provides an implementation.
 */
class PgResult : Result {
	public:
	this (PGresult* results) {
		this.results = results;
		numRows = PQntuples(results);
		numFields = PQnfields(results);
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
		version (Ares) {
			char[] strip (char[] string) {
				return std.regexp.sub(std.regexp.sub(string, "^[ \t\v\r\n\f]+", ""), " [\t\v\r\n\f]+$", "");
			}
		}

		if (index >= numRows) {
			return null;
		}
		Row r = new Row();
		for (int a = 0; a < numFields; a++) {
			r.addField(strip(asString(PQfname(results, a))), strip(asString(PQgetvalue(results, index, a))), "", 0);
		}
		index++;
		return r;
	}

	/**
	 * Free all database resources used by a result set.
	 */
	override void finish () {
		if (results !is null) {
			PQclear(results);
			results = null;
		}
	}

	private:
	PGresult* results;
	int index;
	const int numRows;
	const int numFields;
}
