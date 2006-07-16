/**
 * Authors: The D DBI project
 *
 * Version: 0.2.2
 *
 * Copyright: BSD license
 */
module dbi.mysql.MysqlResult;

private import std.string;
private import dbi.Result, dbi.Row;
private import dbi.mysql.imp;

/**
 * Manage a result set from a MySQL database query.
 *
 * No functions return this.  It should not be used directly.  Use the interface
 * provided by Result instead.
 *
 * See_Also:
 *	Result is the interface that this provides an implementation of.
 */
class MysqlResult : Result {
	public:
	this (MYSQL_RES* res) {
		this.m_res = res;
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
	 */
	override Row fetchRow () {
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
	 * Free all database resources used by a result set.
	 */
	override void finish () {
		if (m_res !is null) {
			mysql_free_result(m_res);
			m_res = null;
		}
	}

	private:
	MYSQL_RES* m_res;
}