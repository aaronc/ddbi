/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.mysql.MysqlDatabase;

version (dbi_mysql) {

private import tango.stdc.stringz : toDString = fromStringz, toCString = toStringz;
private import tango.io.Console;
private static import tango.text.Util;
private static import tango.text.convert.Integer;
debug(UnitTest) import tango.io.Stdout;

private import dbi.Database, dbi.DBIException, dbi.Result, dbi.Row, dbi.Statement, dbi.Registry;
version(Windows) {
	private import dbi.mysql.imp_win;
}
else {
	private import dbi.mysql.imp;
}
private import dbi.mysql.MysqlError, dbi.mysql.MysqlResult;

static this() {
	uint ver = mysql_get_client_version();
	if(ver < 50000) {
		throw new Exception("Unsupported MySQL client version.  Please compile using at least version 5.0 of the MySQL client libray.");
	}
	else if(ver < 50100) {
		if(MYSQL_VERSION != 50000) {
			throw new Exception("You are linking against version 5.0 of the MySQL client library but you have a build switch turned on for a different version (such as MySQL_51).");
		}
	}
	else {
		if(MYSQL_VERSION != 50100) {
			throw new Exception("You are linking against version 5.1 (or higher) of the MySQL client library so you need to use the build switch '-version=MySQL_51'.");
		}
	}
}

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
		connection = mysql_init(null);
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
	 *	DBIException if port is provided but is not an integer.
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
		char[] sock = null;
		uint port = 0;

		void parseKeywords () {
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
                port = cast(uint)tango.text.convert.Integer.parse(keywords["port"]);
			}
		}
        if (tango.text.Util.contains(params, '=')) {
            parseKeywords();
        } else {
            dbname = params;
        }

		mysql_real_connect(connection, toCString(host), toCString(username), toCString(password), toCString(dbname), port, toCString(sock), 0);
		if (uint error = mysql_errno(connection)) {
		        Cout("connect(): ");
		        Cout(toDString(mysql_error(connection)));
		        Cout("\n").flush;			
			throw new DBIException("Unable to connect to the MySQL database.", error, specificToGeneral(error));
		}
	}

	/**
	 * Close the current connection to the database.
	 *
	 * Throws:
	 *	DBIException if there was an error disconnecting.
	 */
	override void close () {
		if (connection !is null) {
			mysql_close(connection);
			if (uint error = mysql_errno(connection)) {
   		                Cout("close(): ");
		                Cout(toDString(mysql_error(connection)));
		                Cout("\n").flush;			
				throw new DBIException("Unable to close the MySQL database.", error, specificToGeneral(error));
			}
			connection = null;
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
		int error = mysql_real_query(connection, toCString(sql), sql.length);
		if (error) {
		        Cout("execute(): ");
		        Cout(toDString(mysql_error(connection)));
		        Cout("\n").flush;			
		        throw new DBIException("Unable to execute a command on the MySQL database.", sql, error, specificToGeneral(error));
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
	override MysqlResult query (char[] sql) {
		mysql_real_query(connection, toCString(sql), sql.length);
		MYSQL_RES* results = mysql_store_result(connection);
		if (results is null) {
		        Cout("query(): ");
 		        Cout(toDString(mysql_error(connection)));
		        Cout("\n").flush;
			throw new DBIException("Unable to query the MySQL database.", sql);
		}
		assert (results !is null);
		return new MysqlResult(results);
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
	        Cout("GetErrorCode: ");
     	        Cout(toDString(mysql_error(connection)));
	        Cout("\n").flush;
		return cast(int)mysql_errno(connection);
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
		return toDString(mysql_error(connection));
	}

	/**
	 * Get the integer id of the last row to be inserted.
	 *
	 * Returns:
	 *	The id of the last row inserted into the database.
	 */
        override long getLastInsertID() {
                return mysql_insert_id(connection);
        }
        
    static this()
    {
    	mysqlSqlGen = new MysqlSqlGenerator;
    }
    private static MysqlSqlGenerator mysqlSqlGen;
        
    override SqlGenerator getSqlGenerator()
	{
		return mysqlSqlGen;
	}

	package:
	MYSQL* connection;
}

class MysqlSqlGenerator : SqlGenerator
{
	override char getIdentifierQuoteCharacter()
	{
		return '`'; 
	}
}

private class MysqlRegister : Registerable {
	
	public char[] getPrefix() {
		return "mysql";
	}
	
	public Database getInstance(char[] url) {
		//parse the URL here
		return new MysqlDatabase();
	}
}

static this() {
	Cout("Attempting to register MysqlDatabase in Registry").newline;
	registerDatabase(new MysqlRegister());
}

debug(UnitTest) {
unittest {

    void s1 (char[] s) {
        tango.io.Stdout.Stdout(s).newline();
    }

    void s2 (char[] s) {
        tango.io.Stdout.Stdout("   ..." ~ s).newline();
    }

	s1("dbi.mysql.MysqlDatabase:");
	MysqlDatabase db = new MysqlDatabase();
/+	s2("connect");
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
	/** Todo: MySQL type retrieval is not functioning */
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
	db.close();+/
    auto sqlgen = db.getSqlGenerator;
    auto res = sqlgen.makeInsertSql("user", ["name", "date"]);
	assert(res == "INSERT INTO `user` (`name`,`date`) VALUES(?,?)", res);
}
}

}
