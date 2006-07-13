/**
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteResult;

private import std.string;
private import dbi.BaseResult, dbi.Row;
private import dbi.sqlite.imp;

/**
 * Manage the results of a sqlite result set. This class implements all
 * of the current DBD Result interface. The interface is not
 * described here again, instead please view Result directly.
 *
 * See_Also:
 *	Result
 */
class SqliteResult : BaseResult {
	public:
	/**
	 * Params:
	 *	stmt = SQLite3 statement structure.
	 */
	this (sqlite3_stmt* stmt) {
		this.stmt = stmt;
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
	override Row fetchRow () {
		if (sqlite3_step(stmt) != SQLITE_ROW) {
			return null;
		}
		Row r = new Row();
		for (int a = 0; a < sqlite3_column_count(stmt); a++) {
			r.addField(std.string.toString(sqlite3_column_name(stmt,a)).dup, std.string.toString(sqlite3_column_text(stmt,a)).dup, std.string.toString(sqlite3_column_decltype(stmt,a)).dup, sqlite3_column_type(stmt,a));
		}
		return r;
	}

	/**
	 *
	 */
	override void finish () {
		if (stmt !is null) {
			sqlite3_finalize(stmt);
			stmt = null;
		}
	}

	private:
	sqlite3_stmt* stmt;
}