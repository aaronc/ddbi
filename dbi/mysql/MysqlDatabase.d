/**
 * Authors: The D DBI project
 *
 * Version: 0.2.4
 *
 * Copyright: BSD license
 */
module dbi.mysql.MysqlDatabase;

version (Ares) {
	private static import std.regexp;
	private import util.string : asString = toString;
	debug (UnitTest) private import std.io.Console;
} else {
	private static import std.string;
	alias std.string.toString asString;
	debug (UnitTest) private import std.stdio;
}
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
		char[] sock = "/tmp/mysql.sock";
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
				port = toInt(keywords["port"]);
			}
		}

		version (Ares) {
			if (std.regexp.find(params, "=") != size_t.max) {
				parseKeywords();
			} else {
				dbname = params;
			}
		} else {
			if (std.string.find(params, "=") != -1) {
				parseKeywords();
			} else {
				dbname = params;
			}
		}

		mysql_real_connect(connection, host, username, password, dbname, port, sock, 0);
		if (uint error = mysql_errno(connection)) {
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
		mysql_close(connection);
		if (uint error = mysql_errno(connection)) {
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
		int error = mysql_real_query(connection, sql, sql.length);
		if (error) {
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
	override MysqlResult query (char[] sql) {
		mysql_real_query(connection, sql, sql.length);
		MYSQL_RES* results = mysql_store_result(connection);
		//if (results is null) {
		//	throw new DBIException("Unable to query the MySQL database.", sql);
		//}
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
		return asString(mysql_error(connection));
	}

	private:
	MYSQL* connection;
}

unittest {
	version (Ares) {
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

	s1("dbi.mysql.MysqlDatabase:");
	MysqlDatabase db = new MysqlDatabase();
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
	db.close();
}

/*
 * Copyright (C) 2002-2006 by Digital Mars, www.digitalmars.com
 * Written by Walter Bright
 * Some parts contributed by David L. Davis
 * Modified for use in D DBI.
 *
 *  This software is provided 'as-is', without any express or implied
 *  warranty. In no event will the authors be held liable for any damages
 *  arising from the use of this software.
 *
 *  Permission is granted to anyone to use this software for any purpose,
 *  including commercial applications, and to alter it and redistribute it
 *  freely, subject to the following restrictions:
 *
 *  o  The origin of this software must not be misrepresented; you must not
 *     claim that you wrote the original software. If you use this software
 *     in a product, an acknowledgment in the product documentation would be
 *     appreciated but is not required.
 *  o  Altered source versions must be plainly marked as such, and must not
 *     be misrepresented as being the original software.
 *  o  This notice may not be removed or altered from any source
 *     distribution.
 */
int toInt (char[] string) {
	if (!string.length) {
		throw new DBIException("Couldn't convert \"" ~ string ~ "\" to type \"int.\"");
	}

	bool negative = false;
	int v = 0;

	for (size_t i = 0; i < string.length; i++) {
		char c = string[i];

		if (c >= '0' && c <= '9') {
			uint v1 = v;
			v = v * 10 + (c - '0');

			if (cast(uint)v < v1) {
				throw new DBIException("Couldn't convert \"" ~ string ~ "\" to type \"int.\"");
			}
		} else if (c == '-' && i == 0) {
			negative = true;

			if (string.length == 1) {
				throw new DBIException("Couldn't convert \"" ~ string ~ "\" to type \"int.\"");
			}
		} else if (c == '+' && i == 0) {
			if (string.length == 1) {
				throw new DBIException("Couldn't convert \"" ~ string ~ "\" to type \"int.\"");
			}
		} else {
			throw new DBIException("Couldn't convert \"" ~ string ~ "\" to type \"int.\"");
		}
	}
	if (negative) {
		if (cast(uint)v > 0x80000000) {
			throw new DBIException("Couldn't convert \"" ~ string ~ "\" to type \"int.\"");
		}

		v = -v;
	} else {
		if (cast(uint)v > 0x7FFFFFFF) {
			throw new DBIException("Couldn't convert \"" ~ string ~ "\" to type \"int.\"");
		}
	}
	return v;
}