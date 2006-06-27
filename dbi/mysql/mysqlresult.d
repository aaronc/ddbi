/**
 * Copyright: LGPL
 */
module dbi.mysql.MysqlResult;

private import std.string;
private import dbi.BaseResult, dbi.Row;
private import dbi.mysql.imp;

/**
 * Manage the results of a mysql result set. This class implements
 * all of the current DBD Result interface. The interface is not
 * described here again, instead please view Result directly.
 *
 * See_Also:
 *	Result
 */
class MysqlResult : BaseResult {
	/**
	 *
	 */
	this (MYSQL_RES* res) {
		this.m_res = res;
	}

	/**
	 *
	 */
	~this () {
		if (m_res != null) {
			finish();
		}
	}

	/**
	 *
	 */
	Row fetchRow () {
		MYSQL_ROW row = mysql_fetch_row(m_res);
		if (row is null) {
			return null;
		}
		MYSQL_FIELD* field;
		int fieldCount = mysql_num_fields(m_res);
		Row r = new Row();
		for (int idx = 0; idx < fieldCount; idx++) {
			field = mysql_fetch_field_direct(m_res, idx);
			r.addField(std.string.toString(field.name), std.string.toString(row[idx]), "", field.type);
		}
		return r;
	}

	/**
	 *
	 */
	void finish () {
		mysql_free_result(m_res);
		m_res = null;
	}

	private:
	MYSQL_RES* m_res;
}