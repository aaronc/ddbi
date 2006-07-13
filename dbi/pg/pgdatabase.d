/**
 * Authors: The D DBI project
 *
 * Copyright: BSD license
 */
module dbi.pg.PgDatabase;

private import std.string;
private import dbi.BaseDatabase, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.pg.imp, dbi.pg.PgResult;

/**
 * Manage a PostgreSQL database connection. This class implements all of
 * the current DBD interface as defined in Database. Functions are
 * not going to be explained in detail here, please see other references
 * listed below.
 *
 * Bugs:
 *	PgDatabase currently does not retrieve column types.
 *
 * See_Also:
 *	BaseDatabase, Database
 */

class PgDatabase : BaseDatabase {
	public:
	/**
	 * Connect to a database.
	 *
	 * Params:
	 *	connString = Connection string.
	 *	user = Username to authenticate with.
	 *	passwd = Password to use for authentication.
	 *
	 * Bugs:
	 *	Doesn't convert the error to ErrorCode.
	 *
	 * Connection String Keywords:
	 *	<http://www.postgresql.org/docs/8.0/static/libpq.html>
	 */
	override void connect (char[] conn, char[] user = null, char[] passwd = null) {
		if (conn == null) {
			conn = "";
		}
		if (user !is null) {
			conn ~= " user=" ~ user ~ "";
		}
		if (passwd !is null) {
			conn ~= " password=" ~ passwd ~ "";
		}
		m_pg = PQconnectdb(conn);
		if ((m_errorCode = cast(size_t)PQstatus(m_pg)) != ConnStatusType.CONNECTION_OK) {
			throw new DBIException (std.string.toString(PQerrorMessage(m_pg)), m_errorCode);
		}
	}

	/**
	 *
	 */
	override void close () {
		PQfinish(m_pg);
		if ((m_errorCode = cast(size_t)PQstatus(m_pg)) != ConnStatusType.CONNECTION_OK) {
			throw new DBIException (std.string.toString(PQerrorMessage(m_pg)), m_errorCode);
		}
	}

	/**
	 *
	 */
	override void execute (char[] sql) {
		PGresult* res = PQexec(m_pg, toStringz(sql.dup));
		scope(exit) PQclear(res);
		if ((m_errorCode = cast(size_t)PQresultStatus(res)) != ExecStatusType.PGRES_COMMAND_OK) {
			throw new DBIException (std.string.toString(PQerrorMessage(m_pg)), m_errorCode);
		}
	}

	/**
	 *
	 */
	override Result query (char[] sql) {
		PGresult* res = PQexec(m_pg, toStringz(sql.dup));
		ExecStatusType status = PQresultStatus(res);
		if ((m_errorCode = cast(size_t)PQresultStatus(res)) != ExecStatusType.PGRES_COMMAND_OK) {
			throw new DBIException (std.string.toString(PQerrorMessage(m_pg)), m_errorCode);
		}
		return new PgResult(res);
	}

	/**
	 *
	 */
	deprecated override int getErrorCode () {
		return m_errorCode;
	}

	/**
	 *
	 */
	deprecated override char[] getErrorMessage () {
		return m_errorString;
	}

	private:
	PGconn* m_pg;
	int m_errorCode;
	char[] m_errorString;
}

unittest {
	void s1 (char[] s) {
		printf("%.*s\n", s);
	}
	void s2 (char[] s) {
		printf("   ...%.*s\n", s);
	}

	s1("dbi.pg.PgDatabase:");
	PgDatabase db = new PgDatabase();
	s2("connect");
	db.connect("dbname=test");

	s2("query");
	Result res = db.query("SELECT * FROM people");
	assert(res != null);

	s2("fetchRow");
	Row row = res.fetchRow();
	assert(row != null);
	assert(row.getFieldIndex("name") == 1);
	//assert(row.getFieldType(1) == FIELD_TYPE_STRING);
	//assert(row.getFieldDecl(1) == "char(40)");
	assert(row.get(0) == "1");
	assert(row.get("name") == "John Doe");
	assert(row["name"]     == "John Doe");
	assert(row.get(2) == "45");
	assert(row[2]     == "45");
	res.finish();

	s2("prepare");
	Statement stmt = db.prepare("SELECT * FROM people WHERE id = ?");
	stmt.bind(1, "1");
	res = stmt.query();
	row = res.fetchRow();
	res.finish();
	assert(row["id"] == "1");

	s2("fetchOne");
	row = db.queryFetchOne("SELECT * FROM people");
	assert(row["id"] == "1");

	s2("execute(INSERT)");
	db.execute("INSERT INTO people VALUES (0, 'Test Doe', '10')");

	s2("execute(DELETE via prepare statement)");
	stmt = db.prepare("DELETE FROM people WHERE id=?");
	stmt.bind(1, "0");
	stmt.execute();

	s2("getErrorCode, getErrorMessage");
	db.execute("SELECT * FROM doesnotexist");

	s2("close");
	db.close();
}