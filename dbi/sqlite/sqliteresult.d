/**
 * Authors: The D DBI project
 *
 * Version: 0.2.3
 *
 * Copyright: BSD license
 */
module dbi.sqlite.SqliteResult;

private static import std.string;
private import dbi.Result, dbi.Row;
private import dbi.sqlite.imp;

/**
 * Manage a result set from a SQLite database query.
 *
 * No functions return this.  It should not be used directly.  Use the interface
 * provided by Result instead.
 *
 * See_Also:
 *	Result is the interface that this provides an implementation of.
 */
class SqliteResult : Result {
	public:
	this (sqlite3_stmt* stmt) {
		this.stmt = stmt;
	}

	/**
	 * Get the next row from a result set.
	 *
	 * Returns:
	 *	A Row object with the queried information or null for an empty set.
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
	 * Free all database resources used by a result set.
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