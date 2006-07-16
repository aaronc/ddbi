/**
 * Authors: The D DBI project
 *
 * Version: 0.2.2
 *
 * Copyright: BSD license
 */
module dbi.mysql.MysqlDatabase;

private import std.conv, std.string;
private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.mysql.imp, dbi.mysql.MysqlError, dbi.mysql.MysqlResult;

/**
 * An implementation of Database for use with MySQL databases.
 *
 * Bugs:
 *	Column types aren't retrieved.
 *
 * See_Also:
 *	Database is the interface that this provides an implementation of.
 */
class MysqlDatabase : Database {
	public:
	/**
	 * Create a new instance of MysqlDatabase, but don't connect.
	 */
	this () {
		m_mysql = mysql_init(null);
	}

	/**
	 * Create a new instance of MysqlDatabase and connect to a server.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] params, char[] username = null, char[] password = null) {
		this();
		connect(params, username, password);
	}

	/**
	 * Connect to a database on a MySQL server.
	 *
	 * Params:
	 *	params = A string in the form "keyword1=value1;keyword2=value2;etc."
	 *	username = The _username to _connect with.
	 *	password = The _password to _connect with.
	 *
	 * Keywords:
	 *	dbname = The name of the database to use.
	 *
	 *	host = The host name of the database to _connect to.
	 *
	 *	port = The port number to _connect to.
	 *
	 *	sock = The socket to _connect to.
	 *
	 * Throws:
	 *	DBIException if there was an error connecting.
	 *
	 *	ConvException if port is provided but is not an integer.
	 *
	 * Examples:
	 *	---
	 *	MysqlDatabase db = new MysqlDatabase();
	 *	db.connect("host=localhost;dbname=test", "username", "password");
	 *	---
	 */
	override void connect (char[] params, char[] username = null, char[] password = null) {
		char[] host = "localhost";
		char[] dbname = "test";
		char[] sock = "/tmp/mysql.sock";
		uint port = 0;

		if (std.string.find(params, "=")) {
			char[][char[]] keywords = getKeywords(params);
			if ("host" in keywords) {
				host = keywords["host"];
			}
			if ("dbname" in keywords) {
				dbname = keywords["dbname"];
			}
			if ("sock" in keywords) {
				sock = keywords["sock"];
			}
			if ("port" in keywords) {
				port = std.conv.toInt(keywords["port"]);
			}
		} else {
			dbname = params;
		}

		mysql_real_connect(m_mysql, host, username, password, dbname, port, sock, 0);
		if (uint error = mysql_errno(m_mysql)) {
			throw new DBIException("Unable to connect to the MySQL database.", error, dbi.mysql.MysqlError.specificToGeneral(error));
		}
	}

	/**
	 * Close the current connection to the database.
	 *
	 * Throws:
	 *	DBIException if there was an error disconnecting.
	 */
	override void close () {
		mysql_close(m_mysql);
		if (uint error = mysql_errno(m_mysql)) {
			throw new DBIException("Unable to close the MySQL database.", error, dbi.mysql.MysqlError.specificToGeneral(error));
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
		if (int error = mysql_real_query(m_mysql, sql, sql.length)) {
			throw new DBIException("Unable to execute a command on the MySQL database.", sql, error, dbi.mysql.MysqlError.specificToGeneral(error));
		}
	}

	/**
	 * Query the database.
	 *
	 * Bugs:
	 *	This does not currently check for errors.
	 *
	 * Params:
	 *	sql = The SQL statement to execute.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 */
	override Result query (char[] sql) {
		mysql_real_query(m_mysql, sql, sql.length);
		MysqlResult res = new MysqlResult(mysql_store_result(m_mysql));
		return res;
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
		return cast(int)mysql_errno(m_mysql);
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
		return std.string.toString(mysql_error(m_mysql));
	}

	private:
	MYSQL* m_mysql;
}

unittest {
	void s1 (char[] s) {
		printf("%.*s\n", s);
	}
	void s2 (char[] s) {
		printf("   ...%.*s\n", s);
	}

	s1("dbi.mysql.MysqlDatabase:");
	MysqlDatabase db = new MysqlDatabase();
	s2("connect");
	db.connect("dbname=test", "test", "test");

	s2("query");
	Result res = db.query("SELECT * FROM people");
	assert(res != null);

	s2("fetchRow");
	Row row = res.fetchRow();
	assert(row != null);
	assert(row.getFieldIndex("name") == 1);
	/** Todo: MySQL type retrieval is not functioning */
	//assert(row.getFieldType(1) == FIELD_TYPE_STRING);
	//assert(row.getFieldDecl(1) == "char(40)");
	assert(row.get(0) == "1");
	assert(row.get("name") == "John Doe");
	assert(row["name"] == "John Doe");
	assert(row.get(2) == "45");
	assert(row[2] == "45");
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