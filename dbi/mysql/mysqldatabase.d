/**
 * Copyright: LGPL
 */
module dbi.mysql.MysqlDatabase;

private import std.conv, std.string;
private import dbi.BaseDatabase, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement;
private import dbi.mysql.all, dbi.mysql.imp, dbi.mysql.MysqlResult;

/**
 * Manage a MySQL database connection. This class implements all of the
 * current DBD interface as defined in Database.
 *
 * Limitations:
 *	MysqlDatabase currently does not retrieve column types.
 *
 * See_Also:
 *	BaseDatabase, Database
 */
class MysqlDatabase : BaseDatabase {
	this () {
	}

	/**
	 * Connect to a database on a MySQL server
	 *
	 * Keywords:
	 *	host = Host name.
	 *	dbname = Database name.
	 *	sock = Socket.
	 *	port = Port number.
	 *
	 * Example:
	 *	(start code)
	 *	MysqlDatabase db = new MysqlDatabase();
	 *	db.connect("host=localhost;dbname=test", "username", "password");
	 *	(end code)
	 */
	void connect (char[] conn, char[] user = null, char[] passwd = null) {
		char[] host = "localhost";
		char[] dbname = "test";
		char[] sock = "/tmp/mysql.sock";
		uint port = 0;

		if (conn.find("=")) {
			char[][char[]] keywords = getKeywords(conn);
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
				port = toInt(keywords["port"]);
			}
		} else {
			dbname = conn;
		}

		m_mysql = mysql_init(null);
		mysql_real_connect(m_mysql, toStringz(host), toStringz(user), toStringz(passwd), toStringz(dbname), port, toStringz(sock), 0);
		if (uint error = mysql_errno(m_mysql)) {
			throw new DBIException("Unable to connect to the MySQL database.", error, specificToGeneral(error));
		}
	}

	/**
	 *
	 */
	void close () {
		mysql_close(m_mysql);
		if (uint error = mysql_errno(m_mysql)) {
			throw new DBIException("Unable to close the MySQL database.", error, specificToGeneral(error));
		}
	}

	/**
	 *
	 */
	void execute (char[] sql) {
		if (int error = mysql_real_query(m_mysql, toStringz(sql), sql.length)) {
			throw new DBIException("Unable to execute a command on the MySQL database.", sql, error, specificToGeneral(error));
		}
	}

	/**
	 *
	 */
	Result query (char[] sql) {
		mysql_real_query(m_mysql, toStringz(sql), sql.length);
		MysqlResult res = new MysqlResult(mysql_store_result(m_mysql));
		return res;
	}

	/**
	 *
	 */
	deprecated int getErrorCode () {
		return cast(int)mysql_errno(m_mysql);
	}

	/**
	 *
	 */
	deprecated char[] getErrorMessage () {
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