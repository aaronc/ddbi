/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.mysql.MysqlDatabase;

version (dbi_mysql) {

import tango.stdc.stringz : toDString = fromStringz, toCString = toStringz;
import tango.io.Console;
static import tango.text.Util;
import Integer = tango.text.convert.Integer;
debug(UnitTest) import tango.io.Stdout;

public import dbi.Database;
private import dbi.DBIException, dbi.Statement, dbi.Registry;
private import dbi.VirtualStatement;
version(Windows) {
	private import dbi.mysql.imp_win;
}
else {
	private import dbi.mysql.imp;
}
private import dbi.mysql.MysqlError, dbi.mysql.MysqlPreparedStatement, dbi.mysql.MysqlVirtualStatement;
import tango.text.Util;

import dbi.util.StringWriter;

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
		mysql = mysql_init(null);
	}

	/**
	 * Create a new instance of MysqlDatabase and connect to a server.
	 *
	 * See_Also:
	 *	connect
	 */
	this (char[] host, char[] port, char[] dbname, char[] params) {
		this();
		connect(host, port, dbname, params);
	}

	/**
	 * Connect to a database on a MySQL server.
	 *
	 * Params:
	 *  host = The host name of the database to _connect to.
	 *  port = The port number to _connect to or null to use the default host. 
	 *  dbname = The name of the database to use.
	 *	params = A string in the form "keyword1=value1&keyword2=value2;etc."
	 *	
	 *
	 * Keywords:

	 *  username = The _username to _connect with.
	 *	password = The _password to _connect with.
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
	 *	db.connect("localhost", null, "test", "username=bob&password=12345");
	 *	---
	 */	
	void connect(char[] host, char[] port, char[] dbname, char[] params)
	{
		char[] sock = null;
		char[] username = null;
		char[] password = null;
		uint portNo = 0;
		if(port.length) portNo = cast(uint)Integer.parse(port);

		void parseKeywords () {
			char[][char[]] keywords = getKeywords(params, "&");
			if ("username" in keywords) {
				username = keywords["username"];
			}
			if ("password" in keywords) {
				password = keywords["password"];
			}
			if ("sock" in keywords) {
				sock = keywords["sock"];
			}
		}
		
		parseKeywords;

		mysql_real_connect(mysql, toCString(host), toCString(username), toCString(password), toCString(dbname), portNo, toCString(sock), 0);
		if (uint error = mysql_errno(mysql)) {
		        Cout("connect(): ");
		        Cout(toDString(mysql_error(mysql)));
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
		if (mysql !is null) {
			mysql_close(mysql);
			if (uint error = mysql_errno(mysql)) {
   		                Cout("close(): ");
		                Cout(toDString(mysql_error(mysql)));
		                Cout("\n").flush;			
				throw new DBIException("Unable to close the MySQL database.", error, specificToGeneral(error));
			}
			mysql = null;
		}
		mysqlSqlGen = null;
	}
	
	void execute(char[] sql)
	{
		int error = mysql_real_query(mysql, sql.ptr, sql.length);
		if (error) {
		        Cout("execute(): ");
		        Cout(toDString(mysql_error(mysql)));
		        Cout("\n").flush;			
		        throw new DBIException("Unable to execute a command on the MySQL database.", sql, error, specificToGeneral(error));
		}
	}
	
	void execute(char[] sql, BindType[] paramTypes, void*[] ptrs)
	{
		auto execSql = new DisposableStringWriter(sql.length * 2);
		virtualBind(sql, paramTypes, ptrs, this.getSqlGenerator, execSql);
		execute(execSql.get);
		execSql.free;
		delete execSql;
	}
        
    MysqlPreparedStatement prepare(char[] sql)
	{
		MYSQL_STMT* stmt = mysql_stmt_init(mysql);
		auto res = mysql_stmt_prepare(stmt, sql.ptr, sql.length);
		if(res != 0) {
			debug(Log) {
				auto err = mysql_stmt_error(stmt);
				log.error("Unable to create prepared statement: \"" ~ sql ~"\", errmsg: " ~ toDString(err));
			}
			//return null;
			auto errno = mysql_stmt_errno(stmt);
			throw new DBIException("Unable to prepare statement: " ~ sql, errno, specificToGeneral(errno));
		}
		return new MysqlPreparedStatement(stmt);
	}
			
    MysqlVirtualStatement virtualPrepare(char[] sql)
    {
    	return new MysqlVirtualStatement(sql, getSqlGenerator, mysql);
    }
	
	void beginTransact()
	{
		const char[] sql = "START TRANSACTION";
		mysql_real_query(mysql, sql.ptr, sql.length);
	}
	
	void rollback()
	{
		mysql_rollback(mysql);
	}
	
	void commit()
	{
		mysql_commit(mysql);
	}
	
	char[] escape(char[] str)
	{
		assert(false, "Not implemented");
		//char* res = new char[str.length];
		char* res;
		mysql_real_escape_string(mysql, res, str.ptr, str.length);
	}
	
	bool hasTable(char[] tablename)
	{
		MYSQL_RES* res = mysql_list_tables(mysql, toCString(tablename));
		if(!res) {
			debug(Log) {
				log.warn("mysql_list_tables returned null in method tableExists()");
				logError;
			}
			return false;
		}
		bool exists = mysql_fetch_row(res) ? true : false;
		mysql_free_result(res);
		return exists;
	}
	
	ColumnInfo[] getTableInfo(char[] tablename)
	{
		char[] q = "SHOW COLUMNS FROM `" ~ tablename ~ "`"; 
		auto ret = mysql_real_query(mysql, q.ptr, q.length);
		if(ret != 0) {
			debug(Log) {
				log.warn("Unable to SHOW COLUMNS for table " ~ tablename);
				logError;
			}
			return null;
		}
		MYSQL_RES* res = mysql_store_result(mysql);
		if(!res) {
			debug(Log) {
				log.warn("Unable to store result for " ~ q);
				logError;
			}
			return null;
		}
		if(mysql_num_fields(res) < 1) {
			debug(Log)
			log.warn("Result stored, but query " ~ q ~ " has no fields");
			return null;
		}
		
		ColumnInfo[] info;
		MYSQL_ROW row = mysql_fetch_row(res);
		while(row != null) {
			ColumnInfo col;
			char[] dbCol = toDString(row[0]).dup;
			col.name = dbCol;
			char[] keyCol = toDString(row[3]);
			if(keyCol == "PRI") col.primaryKey = true;
			info ~= col;
			row = mysql_fetch_row(res);
		}
		mysql_free_result(res);
		return info;
	}
	
	char[] type() { return "Mysql"; }
	
	/+char[] toNativeType(BindType type, ulong limit)
	{
		switch(BindType type)
		{
		case BindType.Null:
		default:
			return null;
		}
	}+/
	
	debug(Log)
	{
		static Logger log;
		static this()
		{
			log = Log.lookup("dbi.mysql.MysqlPreparedStatement.MysqlPreparedStatementProvider");
		}
		
		private void logError()
		{
			char* err = mysql_error(mysql);
			log.trace(toDString(err));
		}
	}
               
    override SqlGenerator getSqlGenerator()
	{
    	if(mysqlSqlGen is null)
    		mysqlSqlGen = new MysqlSqlGenerator(mysql);
		return mysqlSqlGen;
	}
    
    debug(DBITest) {
    	override void doTests()
		{
    		Stdout.formatln("Beginning Mysql Tests");
    		
    		Stdout.formatln("Testing Mysql Prepared Statements");
			auto test = new DBTest(this, false);
			test.run;
			
			/+Stdout.formatln("Testing Mysql Virtual Statements");
			auto testVirtual = new DBTest(this, true);
			testVirtual.run;+/
		}
	}
    
    MYSQL* handle() { return mysql; }

	package:
		MYSQL* mysql;
	
	private:
    	MysqlSqlGenerator mysqlSqlGen;
}

class MysqlSqlGenerator : SqlGenerator
{
	this(MYSQL* mysql)
	{
		this.mysql = mysql;
	}
	
	private MYSQL* mysql;
	
	override char getIdentifierQuoteCharacter()
	{
		return '`'; 
	}
	
	char[] toNativeType(ColumnInfo info)
	{
		char[] getTextBlobPrefix(uint limit)
		{
			if(limit <= ubyte.max) return "TINY";
			else if(limit <= ushort.max) return "";
			else if(limit <= 0x1000000) return "MEDIUM";
			else if(limit <= uint.max) return "LONG";
		}
		
		with(BindType)
		{
			switch(info.type)
			{
			case Bool: return "TINYINT(1)"; 
			case Byte: return "TINYINT";
			case UByte: return "TINYINT UNSIGNED";
			case Short: return "SMALLINT";
			case UShort: return "SMALLINT UNSIGNED";
			case Int: return "INT";
			case UInt: return "INT UNSIGNED";
			case Long: return "BIGINT";
			case ULong: return "UNSIGNED BIGINT";
			case Float: return "FLOAT";
			case Double: return "DOUBLE";
			case String: 
				if(info.limit == 0) return "TINYTEXT";
				else if(info.limit <= 255) return "VARCHAR(" ~ Integer.toString(info.limit) ~ ")";
				else return getTextBlobPrefix(info.limit) ~ "TEXT";
			case Binary:
				if(info.limit == 0) return "TINYBLOB";
				if(info.limit <= 255) return "VARBINARY(" ~ Integer.toString(info.limit) ~ ")";
				else return getTextBlobPrefix(info.limit) ~ "BLOB";
				break;
			case Time:
			case DateTime:
				return "DATETIME";
				break;
			case Null:
				debug assert(false, "Unhandled column type"); //TODO more detailed information;
				break;
			default:
				debug assert(false, "Unhandled column type"); //TODO more detailed information;
				break;
			}
		}
	}
}

private class MysqlRegister : Registerable {

	static this() {
		debug(UnitTest) Cout("Attempting to register MysqlDatabase in Registry").newline;
		registerDatabase(new MysqlRegister());
	}
	
	public char[] getPrefix() {
		return "mysql";
	}
	
	/**
	 * Supports urls of the form mysql://[hostname][:port]/[dbname][?param1][=value1][&param2][=value2]...
	 * 
	 * Note: Does not support failoverhost's as in the MySQL JDBC spec.  Not all parameters
	 * are supported - see the connect method for supported parameters.
	 *
	 */
	public Database getInstance(char[] url) {
		char[] host = "127.0.0.1";
		char[] port, dbname, params;

		auto fields = delimit(url, "/");
		
		if(fields.length) {
			auto fields1 = delimit(fields[0], ":");
			
			if(fields1.length) {
				if(fields1[0].length) host = fields1[0];
				if(fields1.length > 1 && fields1[1].length) port = fields1[1];
			}
			
			if(fields.length > 1) {
				auto fields2 = delimit(fields[1], "?");
				if(fields2.length) { 
					dbname = fields2[0];
					if(fields2.length > 1) params = fields2[1];
				}
			}
		}
		return new MysqlDatabase(host, port, dbname, params);
	}
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

debug(DBITest) {
	
	import tango.util.log.Config;
	import tango.time.Clock;
	
	import dbi.util.DateTime;
	import dbi.ErrorCode;
	
	unittest
	{
		try
		{
			auto db = new MysqlDatabase("localhost", null, "test", "username=test&password=test");
			
			db.test();
			
			db.close;
		}
		catch(DBIException ex)
		{
			Stdout.formatln("Caught DBIException: {}, DBI Code:{}, DB Code:{}, Sql: {}", ex.toString, toString(ex.getErrorCode), ex.getSpecificCode, ex.getSql);
			throw ex;
		}
	}
}

}