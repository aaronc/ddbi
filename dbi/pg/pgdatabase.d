/**
 * Authors: The D DBI project
 *
 * Version: 0.2.3
 *
 * Copyright: BSD license
 */
module dbi.pg.PgDatabase;

private static import std.string;
private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.pg.imp, dbi.pg.PgError, dbi.pg.PgResult;

/**
 * An implementation of Database for use with PostgreSQL databases.
 *
 * Bugs:
 *	Column types aren't retrieved.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class PgDatabase : Database {
	public:
	/**
	 * Create a new instance of PgDatabase, but don't connect.
	 */
	this () {
	}

	/**
	 * Create a new instance of PgDatabase and connect to a server.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] params, char[] username = null, char[] password = null) {
		this();
		connect(params, username, password);
	}

	/**
	 * Connect to a database on a PostgreSQL server.
	 *
	 * Params:
	 *	params = A string in the form "keyword1=value1;keyword2=value2;etc."
	 *	username = The _username to _connect with.
	 *	password = The _password to _connect with.
	 *
	 * Keywords:
	 *	host = The name of the host or socket to _connect to.
	 *
	 *	hostaddr = The IP address of the host to _connect to.
	 *
	 *	port = The port number or socket extension to use.
	 *
	 *	dbname = The name of the database to use.
	 *
	 *	user = The _username to _connect with.
	 *
	 *	_password = The _password to _connect with.
	 *
	 *	connect_timeout = The number of seconds to wait for a connection.
	 *
	 *	options = Command-line options to be sent to the server.
	 *
	 *	tty = Ignored.
	 *
	 *	sslmode = What priority should be placed on using SSL.
	 *
	 *	requiressl = Deprecated.  Use sslmode instead.
	 *
	 *	krbsrvname = Kerberos 5 service name.
	 *
	 *	service = Service name that specifies additional parameters.
	 *
	 * Throws:
	 *	DBIException if there was an error connecting.
	 *
	 * Examples:
	 *	---
	 *	PgDatabase db = new PgDatabase();
	 *	db.connect("host=localhost;dbname=test", "username", "password");
	 *	---
	 *
	 * See_Also::
	 *	http://www.postgresql.org/docs/8.1/static/libpq.html
	 */
	override void connect (char[] params, char[] username = null, char[] password = null) {
		if (params == null) {
			params = "";
		}
		if (username !is null) {
			params ~= " user=" ~ username ~ "";
		}
		if (password !is null) {
			params ~= " password=" ~ password ~ "";
		}
		m_pg = PQconnectdb(params);
		if ((m_errorCode = cast(size_t)PQstatus(m_pg)) != ConnStatusType.CONNECTION_OK) {
			throw new DBIException(std.string.toString(PQerrorMessage(m_pg)), m_errorCode);
		}
	}

	/**
	 * Close the current connection to the database.
	 *
	 * Throws:
	 *	DBIException if there was an error disconnecting.
	 */
	override void close () {
		PQfinish(m_pg);
		if ((m_errorCode = cast(size_t)PQstatus(m_pg)) != ConnStatusType.CONNECTION_OK) {
			throw new DBIException(std.string.toString(PQerrorMessage(m_pg)), m_errorCode);
		}
	}

	/**
	 * Execute a SQL statement that returns no results.
	 *
	 * Params:
	 *	sql = The SQL statement to _execute.
	 *
	 * Throws:
	 *	DBIException if the SQL code couldn't be executed.
	 */
	override void execute (char[] sql) {
		PGresult* res = PQexec(m_pg, sql.dup);
		scope(exit) PQclear(res);
		if ((m_errorCode = cast(size_t)PQresultStatus(res)) != ExecStatusType.PGRES_COMMAND_OK) {
			throw new DBIException(std.string.toString(PQerrorMessage(m_pg)), m_errorCode, specificToGeneral(PQresultErrorField(res, PG_DIAG_SQLSTATE)));
		}
	}

	/**
	 * Query the database.
	 *
	 * Params:
	 *	sql = The SQL statement to execute.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 *
	 * Throws:
	 *	DBIException if the SQL code couldn't be executed.
	 */
	override Result query (char[] sql) {
		PGresult* res = PQexec(m_pg, sql.dup);
		ExecStatusType status = PQresultStatus(res);
		if ((m_errorCode = cast(size_t)PQresultStatus(res)) != ExecStatusType.PGRES_COMMAND_OK) {
			throw new DBIException(std.string.toString(PQerrorMessage(m_pg)), m_errorCode, specificToGeneral(PQresultErrorField(res, PG_DIAG_SQLSTATE)));
		}
		return new PgResult(res);
	}

	/**
	 * Get the error code.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.  This will be
	 *	removed in version 0.3.0.
	 *
	 * Returns:
	 *	The database specific error code.
	 */
	deprecated override int getErrorCode () {
		return m_errorCode;
	}

	/**
	 * Get the error message.
	 *
	 * Deprecated:
	 *	This functionality now exists in DBIException.  This will be
	 *	removed in version 0.3.0.
	 *
	 * Returns:
	 *	The database specific error message.
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