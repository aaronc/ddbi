/**
 * Authors: The D DBI project
 *
 * Version: 0.2.3
 *
 * Copyright: BSD license
 */
module dbi.pg.PgResult;

private static import std.string;
private import dbi.Result, dbi.Row;
private import dbi.pg.imp;

/**
 * Manage a result set from a PostgreSQL database query.
 *
 * No functions return this.  It should not be used directly.  Use the interface
 * provided by Result instead.
 *
 * See_Also:
 *	Result is the interface that this provides an implementation of.
 */
class PgResult : Result {
	public:
	this (PGresult* res) {
		m_res = res;
		m_rows = PQntuples(res);
		m_fields = PQnfields(res);
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
		if (m_rowIdx > m_rows) {
			return null;
		}
		Row r = new Row();
		for (int a = 0; a < m_fields; a++) {
			r.addField(std.string.strip(std.string.toString(PQfname(m_res, a))).dup, std.string.strip(std.string.toString(PQgetvalue(m_res, m_rowIdx, a))).dup, "", 0);
		}
		m_rowIdx += 1;
		return r;
	}

	/**
	 * Free all database resources used by a result set.
	 */
	override void finish () {
		if (m_res != null) {
			PQclear(m_res);
			m_res = null;
		}
	}

	private:
	PGresult* m_res;
	int m_rowIdx;
	int m_rows;
	int m_fields;
}