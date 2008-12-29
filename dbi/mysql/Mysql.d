/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.mysql.Mysql;

version (dbi_mysql) {

import tango.stdc.stringz : toDString = fromStringz, toCString = toStringz;
import TextUtil = tango.text.Util;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;
import tango.time.Time;

import dbi.model.Database;
import dbi.util.DateTime, dbi.util.VirtualPrepare,
	dbi.util.Registry, dbi.util.StringWriter;
import dbi.Exception;

import dbi.mysql.c.mysql;
import dbi.mysql.MysqlError, dbi.mysql.MysqlStatement,
	dbi.mysql.MysqlMetadata, dbi.mysql.MysqlConvert;

debug import tango.util.log.Log;
debug(DBITest) import tango.io.Stdout;


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
class Mysql : Database {
	public:
	/**
	 * Create a new instance of MysqlDatabase, but don't connect.
	 */
	this () {
		mysql = mysql_init(null);
		writer_ = new DisposableStringWriter(5000);
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
		
		bool useSSL = false;
		char[] sslKey, sslCert, sslCa, sslCaPath, sslCipher;
		
		uint client_flag = CLIENT_MULTI_STATEMENTS;

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
			if("allowMultiQueries" in keywords) {
				if(keywords["allowLoadLocalInfile"] == "false")
					client_flag &= ~CLIENT_MULTI_STATEMENTS;
			}
			if("allowLoadLocalInfile" in keywords) {
				if(keywords["allowLoadLocalInfile"] == "true")
					client_flag |= CLIENT_LOCAL_FILES;
			}
			if("useCompression" in keywords) {
				if(keywords["useCompression"] == "true")
					client_flag |= CLIENT_COMPRESS;
			}
			if("useSSL" in keywords) {
				if(keywords["useSSL"] == "true")
					useSSL = true;
			}
			if ("sslKey" in keywords) {
				sslKey = keywords["sslKey"];
			}
			if ("sslCert" in keywords) {
				sslCert = keywords["sslCert"];
			}
			if ("sslCa" in keywords) {
				sslCa = keywords["sslCa"];
			}
			if ("sslCaPath" in keywords) {
				sslCaPath = keywords["sslCaPath"];
			}
			if ("sslCipher" in keywords) {
				sslCipher = keywords["sslCipher"];
			}
		}
		
		parseKeywords;
		
		if(useSSL) {
			mysql_ssl_set(mysql, toCString(sslKey), toCString(sslCert), toCString(sslCa),
				toCString(sslCaPath), toCString(sslCipher));
		}

		mysql_real_connect(mysql, toCString(host), toCString(username), toCString(password), toCString(dbname), portNo, toCString(sock), client_flag);
		if (uint error = mysql_errno(mysql)) {
			debug log.error("connect(): {}", toDString(mysql_error(mysql)));
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
   		        debug log.error("close(): {}", toDString(mysql_error(mysql)));
				throw new DBIException("Unable to close the MySQL database.", error, specificToGeneral(error));
			}
			mysql = null;
		}
		mysqlSqlGen = null;
	}
	
    MysqlStatement doPrepare(char[] sql)
	{
		MYSQL_STMT* stmt = mysql_stmt_init(mysql);
		auto res = mysql_stmt_prepare(stmt, sql.ptr, sql.length);
		if(res != 0) {
			debug {
				auto err = mysql_stmt_error(stmt);
				log.error("Unable to create prepared statement: \"" ~ sql ~"\", errmsg: " ~ toDString(err));
			}
			auto errno = mysql_stmt_errno(stmt);
			auto dErr = toDString(mysql_stmt_error(stmt));
			throw new DBIException("Unable to prepare statement: " ~ dErr, sql, errno, specificToGeneral(errno));
		}
		return new MysqlStatement(stmt,sql);
	}
    
    void initQuery(in char[] sql, bool haveParams)
    {
    		sql_ = sql;
    		if(haveParams) {
    			writer_.reset;
    			paramIndices_ = getParamIndices(sql);
    			paramIdx_ = 0;
    		}
    		else paramIndices_ = null;
    		writerIdx_ = 0;
    }
    
	bool doQuery()
	{
		char[] querySql = null;
		if(!paramIndices_.length) querySql = sql_;
		else {
			writer_ ~= sql_[writerIdx_ .. $];
			writer_ ~= "\0";
			querySql = writer_.get;
			querySql.length = writer_.get.length;
		}
		
		debug log.trace("Querying with sql: {}", querySql);
				
		int error = mysql_real_query(mysql, querySql.ptr, querySql.length);
		if (error) {
			throw new DBIException("mysql_real_query error: " ~ toDString(mysql_error(mysql)), querySql, error, specificToGeneral(error));
		}
		
		result_ = mysql_store_result(mysql);
		getMysqlFieldInfo;
		return true;
	}
	
	private char[] sql_;
	private DisposableStringWriter writer_;
	private size_t[] paramIndices_;
	private size_t writerIdx_, paramIdx_;
	
	private void stepWrite_()
	{
		if(paramIdx_ >= paramIndices_.length) {
			throw new DBIException("Parameter index is out of bounds, index:"
				~ Integer.toString(paramIdx_), sql_);
		}
		writer_ ~= sql_[writerIdx_ .. paramIndices_[paramIdx_]];
		writerIdx_ = paramIndices_[paramIdx_] + 1;
		++paramIdx_;
	}
	
	void setParam(bool val) { stepWrite_; if(val) writer_ ~= "1"; else writer_ ~= "0"; }
	void setParam(ubyte val)
	{ stepWrite_; char[3] buf; writer_ ~= Integer.format(buf,val); }
	void setParam(byte val)
	{ stepWrite_; char[4] buf; writer_ ~= Integer.format(buf,val); }
	void setParam(ushort val)
	{ stepWrite_; char[5] buf; writer_ ~= Integer.format(buf,val); }
	void setParam(short val)
	{ stepWrite_; char[6] buf; writer_ ~= Integer.format(buf,val); }
	void setParam(uint val)
	{ stepWrite_; char[10] buf; writer_ ~= Integer.format(buf,val); }
	void setParam(int val)
	{ stepWrite_; char[11] buf; writer_ ~= Integer.format(buf,val); }
	void setParam(ulong val)
	{ stepWrite_; char[20] buf; writer_ ~= Integer.format(buf,val); }
	void setParam(long val)
	{ stepWrite_; char[21] buf; writer_ ~= Integer.format(buf,val); }
	void setParam(float val)
	{ stepWrite_; char[100] buf; writer_ ~= Float.format(buf,val,10,0); }
	void setParam(double val)
	{ stepWrite_; char[150] buf; writer_ ~= Float.format(buf,val,20,0); }
	void setParam(char[] val)
	{
		stepWrite_;
		writer_ ~= "\'";
		auto buf = writer_.forwardReserve(val.length * 2 + 1); 
		auto resLen = mysql_real_escape_string(mysql, buf.ptr, val.ptr, val.length);
		writer_.forwardAdvance(resLen);
		writer_ ~= "\'";
	}
	
	void setParam(ubyte[] val) { setParam(cast(char[])val); }
	void setParam(void[] val) { setParam(cast(char[])val); }
	
	void setParam(Time val)
	{
		stepWrite_;
		DateTime dateTime;
		Gregorian.generic.split(val, dateTime.date.year, dateTime.date.month, 
			dateTime.date.day, dateTime.date.doy, dateTime.date.dow, dateTime.date.era);
		dateTime.time = val.time;
		writer_ ~= "\'";
		auto res = writer_.getWriteBuffer(19);
		printDateTime(dateTime, res);
		writer_ ~= "\'";
	}
	
	void setParam(DateTime val)
	{
		stepWrite_;
		writer_ ~= "\'";
		auto res = writer_.getWriteBuffer(19);
		printDateTime(val, res);
		writer_ ~= "\'";
	}
	
	ulong lastInsertID()
	{
		return mysql_insert_id(mysql);
	}
	
    alias MysqlStatement StatementT;
	
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
	
	char[] escapeString(char[] str, char[] dst)
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
	
	debug
	{
		static Logger log;
		static this()
		{
			log = Log.lookup("dbi.mysql.MysqlDatabase");
		}
		
		private void logError()
		{
			char* err = mysql_error(mysql);
			log.error(toDString(err));
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
    		
    		Stdout.formatln("Testing Mysql");
			auto test = new DBTest(this);
			test.run;
		}
	}
    
    MYSQL* handle() { return mysql; }
    
	bool moreResults()
    in {
        assert (result_ !is null);
    }
    body {
        if (result_ is null)
            throw new DBIException ("This result set was already closed.");

        return cast(bool)mysql_more_results(mysql);
    }
    

    Result nextResult()
    {
        if (result_ !is null) {
        	mysql_free_result(result_);
        }
        
        rowMetadata_ = null;
        
        auto res = mysql_next_result(mysql);
        if (res == 0) {
        	result_ = mysql_store_result(mysql);
        	getMysqlFieldInfo;
            return this;
        }
        else if(res < 0) return null;
        else {
            throw new DBIException("Failed to retrieve next result set.");
        }
    }

    bool validResult() { return result_ !is null; }
    
    MYSQL_FIELD[] getMysqlFieldInfo()
    {
    	if(result_ is null) return null;
    
    	auto len = mysql_num_fields(result_);
        fields_ = mysql_fetch_fields(result_)[0..len];
        return fields_;
    }
	
    FieldInfo[] rowMetadata()
    {
    	if(result_ is null) return null;
    	if(!fields_.length) getMysqlFieldInfo;    	

        rowMetadata_ = getFieldMetadata(fields_);
        return rowMetadata_;
    }
    
    FieldInfo rowMetadata(size_t idx)
    {
    	if(rowMetadata_ is null) rowMetadata;
    	assert(idx < rowMetadata_.length);
    	return rowMetadata_[idx];
    }

    ulong rowCount() { return mysql_num_rows(result_); }
    ulong fieldCount() { return mysql_num_fields(result_); }
    ulong affectedRows() { return mysql_affected_rows(mysql); }
    
    bool nextRow()
    {
    	if(result_ is null) return false;
    	curRow_ = mysql_fetch_row(result_);
    	if(curRow_ is null) return false;
        curLengths_ = mysql_fetch_lengths(result_);
        return true;
    }
    
    bool getField(inout bool val, size_t idx) { return bindField(val, idx); }    
	bool getField(inout ubyte val, size_t idx) { return bindField(val, idx); }
	bool getField(inout byte val, size_t idx) { return bindField(val, idx); }
	bool getField(inout ushort val, size_t idx) { return bindField(val, idx); }
	bool getField(inout short val, size_t idx) { return bindField(val, idx); }
	bool getField(inout uint val, size_t idx) { return bindField(val, idx); }
	bool getField(inout int val, size_t idx) { return bindField(val, idx); }
	bool getField(inout ulong val, size_t idx) { return bindField(val, idx); }
	bool getField(inout long val, size_t idx) { return bindField(val, idx); }
	bool getField(inout float val, size_t idx) { return bindField(val, idx); }
	bool getField(inout double val, size_t idx) { return bindField(val, idx); }
	bool getField(inout char[] val, size_t idx) { return bindField(val, idx); }
	bool getField(inout ubyte[] val, size_t idx) { return bindField(val, idx); }
	bool getField(inout void[] val, size_t idx) { return bindField(val, idx); }
	bool getField(inout Time val, size_t idx) { return bindField(val, idx); }
	bool getField(inout DateTime val, size_t idx) { return bindField(val, idx); }
	
	bool bindField(Type)(inout Type val, size_t idx)
	{
		if(curRow_ is null) return false;
		if(fields_.length <= idx || curRow_[idx] is null) return false;
		/+debug log.trace("Binding Mysql res field #{}, type {}, length {}, val {}",
			idx, fields_[idx].type, curLengths_[idx], curRow_[idx][0..curLengths_[idx]]);+/
		bindMysqlResField(curRow_[idx][0..curLengths_[idx]],fields_[idx].type, val);
		return true;
	}

	package:
		MYSQL* mysql;

	private:
		MYSQL_RES* result_ = null;
		MYSQL_ROW curRow_ = null;
		MYSQL_FIELD[] fields_;
		uint* curLengths_ = null;
		FieldInfo[] rowMetadata_;
		
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
			case ULong: return "BIGINT UNSIGNED";
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

private class MysqlRegister : IRegisterable {

	static this() {
		debug(DBITest) Stdout("Attempting to register MysqlDatabase in Registry").newline;
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

		auto fields = TextUtil.delimit(url, "/");
		
		if(fields.length) {
			auto fields1 = TextUtil.delimit(fields[0], ":");
			
			if(fields1.length) {
				if(fields1[0].length) host = fields1[0];
				if(fields1.length > 1 && fields1[1].length) port = fields1[1];
			}
			
			if(fields.length > 1) {
				auto fields2 = TextUtil.delimit(fields[1], "?");
				if(fields2.length) { 
					dbname = fields2[0];
					if(fields2.length > 1) params = fields2[1];
				}
			}
		}
		return new Mysql(host, port, dbname, params);
	}
}

debug(DBITest) {
	
	import tango.util.log.Config;
	//import tango.time.Clock;
	
	import dbi.util.DateTime;
	import dbi.ErrorCode;
	
	unittest
	{
		try
		{
			auto db = new Mysql("localhost", null, "test", "username=test&password=test");
			
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