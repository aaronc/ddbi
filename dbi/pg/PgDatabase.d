/**
 * Authors: The D DBI project
 *
 * Version: 0.2.4
 *
 * Copyright: BSD license
 */
module dbi.pg.PgDatabase;

version (Tango) {
	private import tango.stdc.stringz : toDString = fromUtf8z;
	private import tango.stdc.stringz : toCString = toUtf8z;
	debug (UnitTest) private import std.io.Console;
} else {
	private import std.string : toDString = toString;
	private import std.string : toCString = toStringz;
	debug (UnitTest) private import std.stdio;
}
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
		if (params is null) {
			params = "";
		}
		if (username !is null) {
			params ~= " user=" ~ username ~ "";
		}
		if (password !is null) {
			params ~= " password=" ~ password ~ "";
		}
		connection = PQconnectdb(toCString(params));
		m_errorCode = cast(int)PQstatus(connection);
		if (m_errorCode != ConnStatusType.CONNECTION_OK && m_errorCode) {
			throw new DBIException(toDString(PQerrorMessage(connection)), m_errorCode);
		}
	}

	/**
	 * Close the current connection to the database.
	 */
	override void close () {
		if (connection !is null) {
			PQfinish(connection);
			connection = null;
		}
	}

  /* Escape a string using the database's native method if possible
   *
   * Params:
   *  str = The string to escape
   *
   * Returns:
   *  The escaped string.
   */

  override char[] escape (char[] str)
  {
    char[] result;

    if(str == "")
      return str;

    result.length = str.length * 2;

    // It's ok to send str.ptr here because string doesnt need to be 0-term
    int len = PQescapeStringConn(connection, result.ptr, str.ptr, str.length, 
        null);
    result.length = len;

    return result;
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
		PGresult* res = PQexec(connection, toCString(sql.dup));
		scope(exit) PQclear(res);
		m_errorCode = cast(int)PQresultStatus(res);
		if (m_errorCode != ExecStatusType.PGRES_COMMAND_OK && m_errorCode != ExecStatusType.PGRES_TUPLES_OK) {
			throw new DBIException(toDString(PQerrorMessage(connection)), m_errorCode, specificToGeneral(PQresultErrorField(res, PG_DIAG_SQLSTATE)));
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
	override PgResult query (char[] sql) {
		PGresult* res = PQexec(connection, toCString(sql.dup));
		ExecStatusType status = PQresultStatus(res);
		m_errorCode = cast(int)PQresultStatus(res);
		if (m_errorCode != ExecStatusType.PGRES_COMMAND_OK && m_errorCode != ExecStatusType.PGRES_TUPLES_OK) {
			throw new DBIException(toDString(PQerrorMessage(connection)), m_errorCode, specificToGeneral(PQresultErrorField(res, PG_DIAG_SQLSTATE)));
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
	PGconn* connection;
	int m_errorCode;
	char[] m_errorString;
}

unittest {
	version (Tango) {
		void s1 (char[] s) {
			Cout("" ~ s ~ "\n");
		}

		void s2 (char[] s) {
			Cout("   ..." ~ s ~ "\n");
		}
	} else {
		void s1 (char[] s) {
			writefln("%s", s);
		}

		void s2 (char[] s) {
			writefln("   ...%s", s);
		}
	}

	s1("dbi.pg.PgDatabase:");
	PgDatabase db = new PgDatabase();
	s2("connect");
	db.connect("dbname=test", "test", "test");

	s2("query");
	Result res = db.query("SELECT * FROM test");
	assert (res !is null);

	s2("fetchRow");
	Row row = res.fetchRow();
	assert (row !is null);
	assert (row.getFieldIndex("id") == 0);
	assert (row.getFieldIndex("name") == 1);
	assert (row.getFieldIndex("dateofbirth") == 2);
	assert (row.get("id") == "1");
	assert (row.get("name") == "John Doe");
	assert (row.get("dateofbirth") == "1970-01-01");
	/** Todo: PostgreSQL type retrieval is not functioning */
	//assert (row.getFieldType(1) == FIELD_TYPE_STRING);
	//assert (row.getFieldDecl(1) == "char(40)");
	res.finish();

	s2("prepare");
	Statement stmt = db.prepare("SELECT * FROM test WHERE id = ?");
	stmt.bind(1, "1");
	res = stmt.query();
	row = res.fetchRow();
	res.finish();
	assert (row[0] == "1");

	s2("fetchOne");
	row = db.queryFetchOne("SELECT * FROM test");
	assert (row[0] == "1");

	s2("execute(INSERT)");
	db.execute("INSERT INTO test VALUES (2, 'Jane Doe', '2000-12-31')");

	s2("execute(DELETE via prepare statement)");
	stmt = db.prepare("DELETE FROM test WHERE id=?");
	stmt.bind(1, "2");
	stmt.execute();

	s2("close");
	db.close();
}
