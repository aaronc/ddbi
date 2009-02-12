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
import tango.core.Thread;

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
	/**
	 * Create a new instance of MysqlDatabase, but don't connect.
	 */
	this () {
		mysql = mysql_init(null);
		writer_ = new SqlStringWriter(short.max);
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
				if(keywords["allowMultiQueries"] == "false") {
					client_flag &= ~CLIENT_MULTI_STATEMENTS;
					allowMultiQueries = false;
				}
				else {
					client_flag |= CLIENT_MULTI_STATEMENTS;
					allowMultiQueries = true;
				}
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
	
    bool enabled(DbiFeature feature)
    {
    	switch(feature)
		{
		case DbiFeature.MultiStatements: return allowMultiQueries;
		default: return false;
		}
    }
    private bool allowMultiQueries = true;

	/**
	 * Close the current connection to the database.
	 *
	 * Throws:
	 *	DBIException if there was an error disconnecting.
	 */
	override void close () {
		debug log.trace("Closing: checking for null handle");
		if (mysql !is null) {
			debug log.trace("Closing database: handle isn't null");
		//	closeResult;
			mysql_close(mysql);
			if (uint error = mysql_errno(mysql)) {
   		        debug log.error("close(): {}", toDString(mysql_error(mysql)));
				throw new DBIException("Unable to close the MySQL database.", error, specificToGeneral(error));
			}
			scope(exit) mysql = null;
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
    			writeFiber_ = new Fiber(&virtualPrepare);
    			writeFiber_.call;
    		}
    }
    
    void initInsert(char[] tablename, char[][] fields)
	{
		sql_ = "Generating INSERT sql for " ~ tablename;
		tablename_ = tablename;
		fieldnames_ = fields;
		writeFiber_ = new Fiber(&writeInsert);
    	writeFiber_.call;
	}
	
	void initUpdate(char[] tablename, char[][] fields, char[] where)
	{
		sql_ = "Generating UPDATE sql for " ~ tablename;
		tablename_ = tablename;
		fieldnames_ = fields;
		where_ = where;
		writeFiber_ = new Fiber(&writeUpdate);
    	writeFiber_.call;
	}
	
	void initSelect(char[] tablename, char[][] fields, char[] where, bool haveParams)
	{
		prepWriterForNewStatement;
		writer_ ~= "SELECT ";
		foreach(fieldname; fields)
		{
			writer_ ~= "`";
			writer_ ~= fieldname;
			writer_ ~= "`,";
		}
		writer_.backup;
		writer_ ~= " FROM `";
		writer_ ~= tablename;
		writer_ ~= "` ";
		
		if(haveParams) {
			where_ = where;
			sql_ = writer_.get;
			writeFiber_ = new Fiber(&writeWhereClause);
    		writeFiber_.call;
		}
		else {
			writer_ ~= where;
			sql_ = writer_.get;
		}
	}
	
	void initRemove(char[] tablename, char[] where, bool haveParams)
	{
		prepWriterForNewStatement;
		writer_ ~= "DELETE FROM `";
		writer_ ~= tablename;
		writer_ ~= "` ";
		
		if(haveParams) {
			where_ = where;
			sql_ = writer_.get;
			writeFiber_ = new Fiber(&writeWhereClause);
    		writeFiber_.call;
		}
		else {
			writer_ ~= where;
			sql_ = writer_.get;
		}
	}
    
	void doQuery()
	{
		scope(exit) multiWriteState_ = MultiWriteState.Off;
		
		if(writeFiber_) if(writeFiber_) finishWriteFiber;
		
		debug log.trace("Querying with sql: {}", sql_);
				
		int error = mysql_real_query(mysql, sql_.ptr, sql_.length);
		if (error) {
			throw new DBIException("mysql_real_query error: " ~ toDString(mysql_error(mysql)), sql_, error, specificToGeneral(error));
		}
		
		result_ = mysql_store_result(mysql);
		getMysqlFieldInfo;
	}
	
	private Fiber writeFiber_;
	private char[] sql_;
	private char[] tablename_;
	private char[] where_;
	private char[][] fieldnames_;
	private SqlStringWriter writer_;
	
	private void virtualPrepare()
	{
		assert(sql_.length);
		prepWriterForNewStatement;
		auto paramIndices = getParamIndices(sql_);
		size_t writerIdx = 0;
		Fiber.yield;
		
		foreach(idx; paramIndices)
		{
			writer_ ~= sql_[writerIdx .. idx];
			writerIdx = idx + 1;
			Fiber.yield;
		}
		
		writer_ ~= sql_[writerIdx .. $];
		sql_ = writer_.get;
	}
	
	private void writeInsert()
	{
		prepWriterForNewStatement;
		assert(tablename_.length && fieldnames_.length);
		writer_ ~= "INSERT INTO `" ~ tablename_ ~ "` (";
		foreach(fieldname; fieldnames_)
		{
			writer_ ~= "`" ~ fieldname ~ "`,";
		}
		writer_.backup;
		writer_ ~= ") VALUES(";
		Fiber.yield;
		
		auto n = fieldnames_.length;
		for(uint i = 0; i < n - 1; ++i)
		{
			Fiber.yield;
			writer_ ~= ",";
		}
		Fiber.yield;
		writer_ ~= ")";
		sql_ = writer_.get;
		tablename_ = null;
		fieldnames_ = null;
	}
	
	
	private void finishWriteFiber() {
		assert(writeFiber_ !is null);
		assert(writeFiber_.state == Fiber.State.HOLD, "Param index out of bounds, sql: " ~ sql_);
		writeFiber_.call;
		assert(writeFiber_.state == Fiber.State.TERM, "Param index out of bounds, sql: " ~ sql_);
		writeFiber_ = null;
	}
	
	private void prepWriterForNewStatement()
	{
		if(multiWriteState_ == MultiWriteState.Off) writer_.reset;
		else if(multiWriteState_ == MultiWriteState.On) {
			if(writeFiber_) finishWriteFiber;
			writer_ ~= ";";
		}
		else {
			assert(multiWriteState_ == MultiWriteState.First);
			writer_.reset;
			multiWriteState_ = MultiWriteState.On;
		}
	}
	
	private void writeUpdate()
	{
		prepWriterForNewStatement;
		assert(tablename_.length && fieldnames_.length && where_.length);
		writer_ ~= "UPDATE  `" ~ tablename_ ~ "` SET ";
		Fiber.yield;
		foreach(fieldname; fieldnames_)
		{
			writer_ ~= "`" ~ fieldname ~ "` = ";
			Fiber.yield;
			writer_ ~= ",";
		}
		writer_.backup;
		writer_ ~= " ";
		
		auto paramIndices = getParamIndices(where_);
		size_t writerIdx = 0;
	
		foreach(idx; paramIndices)
		{
			writer_ ~= where_[writerIdx .. idx];
			writerIdx = idx + 1;
			Fiber.yield;
		}
		
		writer_ ~= where_[writerIdx .. $];
		
		sql_ = writer_.get;
		tablename_ = null;
		fieldnames_ = null;
		where_ = null;
	}
	
	private void writeWhereClause()
	{
		assert(where_.length);
	
		auto paramIndices = getParamIndices(where_);
		size_t writerIdx = 0;
		
	
		foreach(idx; paramIndices)
		{
			writer_ ~= where_[writerIdx .. idx];
			writerIdx = idx + 1;
			Fiber.yield;
		}
		writer_ ~= where_[writerIdx .. $];
		Fiber.yield;
		sql_ = writer_.get;
		where_ = null;
	}
	
	private void stepWrite_()
	{
		assert(writeFiber_ !is null && writeFiber_.state == Fiber.State.HOLD,
			"Param index out of bounds, sql: " ~ sql_);
		writeFiber_.call;
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
		writer_.write(val.length * 2 + 1, (void[] buf) {
			debug assert(buf.length >= val.length * 2 + 1);
			return mysql_real_escape_string(mysql, cast(char*)buf.ptr, val.ptr, val.length);
		});
		//writer_.forwardAdvance(resLen);
		writer_ ~= "\'";
	}
	
	void setParam(ubyte[] val) { setParam(cast(char[])val); }
	
	void setParam(Time val)
	{
		DateTime dateTime;
		Gregorian.generic.split(val, dateTime.date.year, dateTime.date.month, 
			dateTime.date.day, dateTime.date.doy, dateTime.date.dow, dateTime.date.era);
		dateTime.time = val.time;
		setParam(dateTime);
	}
	
	void setParam(DateTime val)
	{
		stepWrite_;
		writer_ ~= "\'";
		auto res = writer_.getWriteBuffer(19);
		printDateTime(val, res);
		writer_ ~= "\'";
	}
	
	void setParamNull() { writer_ ~= "NULL"; }
	
	bool startWritingMultipleStatements()
	{
		if(multiWriteState_ != MultiWriteState.Off) throw new DBIException("Cannot call "
			"startWritingMultipleStatements for database Mysql at this time - "
			"command out of order - looks like you already called this before committing "
			"the last query. startWritingMultipleStatements is on until the query is executed.",
			sql_);
		multiWriteState_ = MultiWriteState.First;
		return true;
	}
	
	bool isWritingMultipleStatements()
	{
		return multiWriteState_ != MultiWriteState.Off ? true : false;
	}
	
	ulong lastInsertID()
	{
		return mysql_insert_id(mysql);
	}
	
    alias MysqlStatement StatementT;
	
	void startTransaction()
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
	
	char[] escapeString(char[] str, char[] dst = null)
	{
		/+assert(dst.length >= 2 * str.length + 1, "Destination string length " 
			"must be at least 2 * source string length + 1");+/
		if(dst.length < str.length * 2 + 1)
			dst.length = str.length *2 + 1;
		auto len = mysql_real_escape_string(mysql, dst.ptr, str.ptr, str.length);
		return dst[0..len];
	}
	
	bool hasTable(char[] tablename)
	{
		MYSQL_RES* res = mysql_list_tables(mysql, toCString(tablename));
		scope(exit) mysql_free_result(res);
		if(!res) {
			debug(Log) {
				log.warn("mysql_list_tables returned null in method tableExists()");
				logError;
			}
			return false;
		}
		bool exists = mysql_fetch_row(res) ? true : false;
		return exists;
	}
	
	ColumnInfo[] getTableInfo(char[] tablename)
	{
		query("SHOW COLUMNS FROM `" ~ tablename ~ "`");
		
		ColumnInfo[] info;
		
		while(this.nextRow) {
			ColumnInfo col;
			char[] keyCol;
			getField(col.name, 0);
			getField(keyCol,3);
			if(keyCol == "PRI") col.primaryKey = true;
			info ~= col;
		}
		
		closeResult;
		return info;
	}
	
	char[] type() { return "Mysql"; }
	
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
    

    MYSQL* handle() { return mysql; }
    
	bool moreResults()
	{
        return cast(bool)mysql_more_results(mysql);
    }
    

    bool nextResult()
    {
        if (result_ !is null) {
			mysql_free_result(result_);
        }
        
        rowMetadata_ = null;
        
        auto res = mysql_next_result(mysql);
        if (res == 0) {
        	result_ = mysql_store_result(mysql);
        	getMysqlFieldInfo;
            return true;
        }
        else if(res < 0) return false;
        else {
            throw new DBIException("Failed to retrieve next result set.");
        }
    }

    bool validResult() { return result_ !is null; }
    void closeResult()
    {
    	int res = 0;
    	while(res == 0) {
	    	if (result_ !is null) {
	        	mysql_free_result(result_);
	        	result_ = null;
	        }
	        res = mysql_next_result(mysql);
	    }
    }
    
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
	
	SqlStringWriter buffer() { return writer_; }
	void buffer(SqlStringWriter) { return writer_; }
	
    debug(DBITest) {
		override void doTests()
		{
			Stdout.formatln("Beginning Mysql Tests");
			
			Stdout.formatln("Testing Mysql");
			auto test = new DBTest(this);
			test.run;
	    }
	}

	package:
		MYSQL* mysql;

	private:
		MYSQL_RES* result_ = null;
		MYSQL_ROW curRow_ = null;
		MYSQL_FIELD[] fields_;
		uint* curLengths_ = null;
		FieldInfo[] rowMetadata_;
		
		enum MultiWriteState { Off, First, On };
		MultiWriteState multiWriteState_ = MultiWriteState.Off;
		
    	MysqlSqlGenerator mysqlSqlGen;
}

class MysqlSqlGenerator : SqlGenerator
{
	this(MYSQL* mysql)
	{
		this.mysql = mysql;
	}
	
	private MYSQL* mysql;
	
	override char identifierQuoteChar()
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