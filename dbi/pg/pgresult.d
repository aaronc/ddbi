/**
 * Copyright: LGPL
 */
module dbi.pg.PgResult;

private import std.string;
private import dbi.BaseResult, dbi.Row;
private import dbi.pg.imp;

/**
 * Manage the results of a PostgreSQL result set. This class
 * implements all of the current DBD Result interface. The
 * interface is not described here again, instead please view
 * Result directly.
 *
 * See_Also:
 *	Result
 */

class PgResult : BaseResult {
	/**
	 * Params:
	 *	res = PostgreSQL result structure.
	 */
	this (PGresult* res) {
		m_res = res;
		m_rows = PQntuples(res);
		m_fields = PQnfields(res);
	}

	/**
	 *
	 */
	~this () {
		finish();
	}

	 /**
	  *
	  */
	Row fetchRow () {
		if (m_rowIdx > m_rows) {
			return null;
		}
		Row r = new Row();
		for (int a=0; a < m_fields; a++) {
			r.addField(std.string.toString(PQfname(m_res, a)).strip().dup, std.string.toString(PQgetvalue(m_res, m_rowIdx, a)).strip().dup, "", 0);
		}
		m_rowIdx += 1;
		return r;
	}

	/**
	 *
	 */
	void finish () {
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