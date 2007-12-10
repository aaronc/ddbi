module dbi.mysql.MysqlPreparedStatement;

version(dbi_mysql) {

	version (Phobos) {
		private static import std.conv, std.string;
		private alias std.string.toString toDString;
		private alias std.string.toStringz toCString;
		debug (UnitTest) private static import std.stdio;
	} else {
		private import tango.stdc.string;
		private import tango.stdc.stringz : toDString = fromUtf8z, toCString = toUtf8z;
	        private import tango.io.Console;
		private static import tango.text.Util;
		private import Integer = tango.text.convert.Integer;
		debug(UnitTest) {
			import tango.stdc.stringz;
			import tango.io.Stdout;
			import tango.util.log.ConsoleAppender;
		}
	}
	debug(Log) {
		import tango.util.log.Log;
	}
	
import dbi.mysql.MysqlDatabase;
import dbi.mysql.imp;
import dbi.PreparedStatement;

class MysqlPreparedStatementProvider : IPreparedStatementProvider
{
	debug(Log)
	{
		static Logger log;
		static this()
		{
			log = Log.getLogger("dbi.mysql.MysqlPreparedStatement.MysqlPreparedStatementProvider");
		}
	}
	
	this(MysqlDatabase db)
	{
		if(!db.connection) throw new Exception("Attempting to create prepared statements but not connected to database");
		mysql = db.connection;
	}
	
	private	MYSQL* mysql;
	
	IPreparedStatement prepare(string sql)
	{
		MYSQL_STMT* stmt = mysql_stmt_init(mysql);
		auto res = mysql_stmt_prepare(stmt, toCString(sql), sql.length);
		if(res != 0) {
			debug(Log) {
				auto err = mysql_stmt_error(stmt);
				log.error("Unable to create prepared statement: \"" ~ sql ~"\", errmsg: " ~ toDString(err));
			}
			return null;
		}
		return new MysqlPreparedStatement(stmt);
	}
}

class MysqlPreparedStatement : IPreparedStatement
{
	uint getParamCount()
	{
		return mysql_stmt_param_count(stmt);
	}
	
	FieldInfo[] getResultMetadata()
	{
		MYSQL_RES* res = mysql_stmt_result_metadata(stmt);
		if(!res) return null;
		uint nFields = mysql_num_fields(res);
		if(!nFields) return null;
		
		MYSQL_FIELD* fields = mysql_fetch_fields(res);
		FieldInfo[] metadata;
		
		metadata.length = nFields;
		
		for(uint i = 0; i < nFields; i++)
		{
			metadata[i].name = fields[i].name[0 .. fields[i].name_length];
			metadata[i].type = fromMysqlType(fields[i].type, fields[i].flags);
		}
		mysql_free_result(res);
		return metadata;
	}
	
	void setParamTypes(BindType[] paramTypes)
	{
		initBindings(paramTypes, paramBind, paramHelper);
	}
	
	void setResultTypes(BindType[] resTypes)
	{
		initBindings(resTypes, resBind, resHelper);
	}
	
	bool execute()
	{
		return mysql_stmt_execute(stmt) == 0 ? true : false;
	}
	
	bool execute(void*[] bind)
	{
		if(!bind || !paramBind) throw new Exception("Attempting to execute a statement without having set parameters types or based a valid bind array.");
		if(bind.length != paramBind.length) throw new Exception("Incorrect number of pointers in bind array");
		
		uint len = bind.length;
		for(uint i = 0; i < len; ++i)
		{
			with(enum_field_types)
			{
			switch(paramBind[i].buffer_type)
			{
			case(MYSQL_TYPE_STRING):
			case(MYSQL_TYPE_BLOB):
				ubyte[]* arr = cast(ubyte[]*)(bind[i]);
				paramBind[i].buffer = (*arr).ptr;
				auto l = (*arr).length;
				paramBind[i].buffer_length = l;
				paramHelper.len[i] = l;
				break;
		/*	case(BindType.Date):
				auto date = *cast(Date*)(paramPtr + paramCols[i].offset);
				paramHelper.time[i].year = date.year;
				paramHelper.time[i].month = date.month;
				paramHelper.time[i].day = date.day;
				paramHelper.time[i].hour = date.hour;
				paramHelper.time[i].minute = date.min;
				paramHelper.time[i].second = date.sec;
				break;*/
			case(MYSQL_TYPE_DATETIME):
				auto dateTime = *cast(DateTime*)(bind[i]);
				paramHelper.time[i].year = dateTime.year;
				paramHelper.time[i].month = dateTime.month;
				paramHelper.time[i].day = dateTime.day;
				paramHelper.time[i].hour = dateTime.hour;
				paramHelper.time[i].minute = dateTime.minute;
				paramHelper.time[i].second = dateTime.second;
				break;
			default:
				paramBind[i].buffer = bind[i];
				break;
			}
			}
		}
		
		auto res = mysql_stmt_bind_param(stmt, paramBind.ptr);
		if(res != 0) return false;
		res = mysql_stmt_execute(stmt);
		return res == 0 ? true : false;
	}
	
	bool fetch(void*[] bind)
	{
		if(!bind || !resBind) throw new Exception("Attempting to fetch from a statement without having set parameters types or based a valid bind array.");
		if(bind.length != resBind.length) throw new Exception("Incorrect number of pointers in bind array");
		
		uint len = bind.length;
		for(uint i = 0; i < len; ++i)
		{
			with(enum_field_types)
			{
			switch(resBind[i].buffer_type)
			{
			case(MYSQL_TYPE_STRING):
			case(MYSQL_TYPE_BLOB):
				/*ubyte[]* arr = cast(ubyte[]*)(bind[i]);
				(*arr).length = 256;
				resBind[i].buffer_length = 256;
				resHelper.len[i] = 256;
				resBind[i].buffer = (*arr).ptr;*/
				ubyte[] buf;
				buf.length = 255;
				resHelper.buffer[i] = buf;
				resBind[i].buffer = buf.ptr;
				resBind[i].buffer_length = 255;
				resHelper.len[i] = 255;
				break;
			case(MYSQL_TYPE_DATETIME):
				break;
			default:
				resBind[i].buffer = bind[i];
				break;
			}
			}
		}
		
		my_bool bres = mysql_stmt_bind_result(stmt, resBind.ptr);
		if(bres != 0) {
			debug(Log) {
				log.error("Unable to bind result params");
				logError;
			}
			return false;
		}
		int res = mysql_stmt_fetch(stmt);
		if(res == 1) {
			debug(Log) {
				log.error("Error fetching result data");
				logError;
			}
			return false;
		}
		if(res == MYSQL_NO_DATA) {
			reset;
			return false;
		}
		
		foreach(i, mysqlTime; resHelper.time)
		{
			DateTime* dateTime = cast(DateTime*)(bind[i]);
			*dateTime = DateTime(mysqlTime.year, mysqlTime.month, mysqlTime.day);
			(*dateTime).addHours(mysqlTime.hour);
			(*dateTime).addMinutes(mysqlTime.minute);
			(*dateTime).addSeconds(mysqlTime.second);
		}
		
		/*	case Type.Date:
		Date* date = cast(Date*)(bind[i]);
		(*date).year = resHelper.time[i].year;
		(*date).month = resHelper.time[i].month;
		(*date).day = resHelper.time[i].day;
		(*date).hour = resHelper.time[i].hour;
		(*date).min = resHelper.time[i].minute;
		(*date).sec = resHelper.time[i].second;						
		break;*/
		if(res == 0) {
			/+for(uint i = 0; i < resBind.length; ++i)
			{
				if(resBind[i].buffer_type != enum_field_types.MYSQL_TYPE_STRING ||
					   resBind[i].buffer_type != enum_field_types.MYSQL_TYPE_BLOB)
				{
					ubyte[]* arr = cast(ubyte[]*)(bind[i]);
					//(*arr) = (*arr)[0 .. resHelper.len[i]];
					uint l = resHelper.len[i];
					*arr = resHelper.buffer[i][0 .. l];
				}
				
			}+/
			foreach(i, buf; resHelper.buffer)
			{
				ubyte[]* arr = cast(ubyte[]*)(bind[i]);
				uint l = resHelper.len[i];
				*arr = buf[0 .. l];
			}
			return true;
		}
		else if(res == MYSQL_DATA_TRUNCATED)
		{
			foreach(i, buf; resHelper.buffer)
			{
				ubyte[]* arr = cast(ubyte[]*)(bind[i]);
				uint l = resHelper.len[i];
				
				if(resBind[i].error) {
					buf.length = l;
					resBind[i].buffer_length = l;
					resBind[i].buffer = buf.ptr;
					if(mysql_stmt_fetch_column(stmt, &resBind[i], i, 0) != 0) {
						debug(Log) {
							log.error("Error fetching String of Binary that failed due to truncation");
							logError;
						}
						return false;
					}
				}
				*arr = buf[0 .. l];
			}
		/+	for(uint i = 0; i < resBind.length; ++i)
			{
				if(*(resBind[i].error))
				{
					if(resBind[i].buffer_type != enum_field_types.MYSQL_TYPE_STRING ||
					   resBind[i].buffer_type != enum_field_types.MYSQL_TYPE_BLOB)
					{
						debug(Log) {
							log.error("Error in column that is not String of Binary type");
							logError;
						}
						return false;
					}
					
					
					ubyte[]* arr = cast(ubyte[]*)(bind[i]);
					if(!arr) {
						debug(Log) {
							log.error("Error retrieving String of Binary in bind parameters");
							logError;
						}
						return false;
					}
					//(*arr).length = *(resBind[i].length);
					//resBind[i].buffer_length = *(resBind[i].length);
					uint l = resHelper.len[i];
					resHelper.buffer[i].length = l;
					resBind[i].buffer_length = l;
					resBind[i].buffer = resHelper.buffer[i].ptr;
					if(mysql_stmt_fetch_column(stmt, &resBind[i], i, 0) != 0) {
						debug(Log) {
							log.error("Error fetching String of Binary that failed due to truncation");
							logError;
						}
						return false;
					}
				}
			}+/
			return true;
		}
		else if(res == MYSQL_NO_DATA) return false;
		else return false;
	}
	
	void prefetchAll()
	{
		mysql_stmt_store_result(stmt);
	}
	
	void reset()
	{
		mysql_stmt_free_result(stmt);
		//mysql_stmt_reset(stmt);
	}
	
	ulong getLastInsertID()
	{
		return mysql_stmt_insert_id(stmt);
	}
	
	char[] getLastErrorMsg()
	{
		return toDString(mysql_stmt_error(stmt));
	}
	
	private this(MYSQL_STMT* stmt)
	{
		this.stmt = stmt;
	}
	
	~this()
	{
		mysql_stmt_close(stmt);
	}
	
	private MYSQL_STMT* stmt;
	private MYSQL_BIND[] paramBind;
	private BindingHelper paramHelper;
	private MYSQL_BIND[] resBind;
	private BindingHelper resHelper;
	
	private static struct BindingHelper
	{	
		void setLength(size_t l)
		{
			error.length = l;
			is_null.length = l;
			len.length = l;
			time = null;
			buffer = null;
			foreach(ref n; is_null)
			{
				n = false;
			}
			
			foreach(ref e; error)
			{
				e = false;
			}
			
			foreach(ref i; len)
			{
				i = 0;
			}
		}
		my_bool[] error;
		my_bool[] is_null;
		uint[] len;
		MYSQL_TIME[uint] time;
		ubyte[][uint] buffer;
	}
	
	private static BindType fromMysqlType(enum_field_types type, uint flags)
	{
		bool unsigned = flags & UNSIGNED_FLAG ? true : false;
		with(enum_field_types) {
		with(BindType) {
			switch(type)
			{
			case MYSQL_TYPE_BIT:
				return Bool;
			case MYSQL_TYPE_TINY:
				return unsigned ? UByte : Byte;
            case MYSQL_TYPE_SHORT:
            	return unsigned ? UShort : Short;
            case MYSQL_TYPE_LONG:
            case MYSQL_TYPE_INT24:
            	return unsigned ? UInt : Int;
            case MYSQL_TYPE_LONGLONG:
            	return unsigned ? ULong : Long;
			case MYSQL_TYPE_DECIMAL:
            case MYSQL_TYPE_FLOAT:
            	return Float;
            case MYSQL_TYPE_DOUBLE:
            	return Double;
            case MYSQL_TYPE_TIMESTAMP:
            case MYSQL_TYPE_DATE:
            case MYSQL_TYPE_TIME:
            case MYSQL_TYPE_DATETIME:
            	return Time;
            case MYSQL_TYPE_VAR_STRING:
            case MYSQL_TYPE_STRING:
            case MYSQL_TYPE_VARCHAR:
            	return String;
            case MYSQL_TYPE_NULL:
            	return Null;
            case MYSQL_TYPE_TINY_BLOB:
            case MYSQL_TYPE_MEDIUM_BLOB:
            case MYSQL_TYPE_LONG_BLOB:
            case MYSQL_TYPE_BLOB:
            	return Binary;  	
            case MYSQL_TYPE_YEAR:
            case MYSQL_TYPE_NEWDATE:
            case MYSQL_TYPE_NEWDECIMAL:
            case MYSQL_TYPE_ENUM:
            case MYSQL_TYPE_SET:
			case MYSQL_TYPE_GEOMETRY:
			default:
				debug assert(false, "Unsupported type");
				return Null;
			}
		}
		}
	}
	
	private static void initBindings(BindType[] types, inout MYSQL_BIND[] bind, inout BindingHelper helper)
	{
		size_t l = types.length;
		bind.length = l;
		foreach(ref b; bind)
		{
			memset(&b, 0, MYSQL_BIND.sizeof);
		}
		helper.setLength(l);
		for(size_t i = 0; i < l; ++i)
		{
			switch(types[i])
			{
			case(BindType.Bool):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_TINY;
				bind[i].is_unsigned = false;
				break;
			case(BindType.Byte):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_TINY;
				bind[i].is_unsigned = false;
				break;
			case(BindType.Short):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_SHORT;
				bind[i].is_unsigned = false;
				break;
			case(BindType.Int):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_LONG;
				bind[i].buffer_length = 4;
				bind[i].is_unsigned = false;
				break;
			case(BindType.Long):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_LONGLONG;
				bind[i].buffer_length = 8;
				bind[i].is_unsigned = false;
				break;
			case(BindType.UByte):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_TINY;
				bind[i].is_unsigned = true;
				break;
			case(BindType.UShort):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_SHORT;
				bind[i].is_unsigned = true;
				break;
			case(BindType.UInt):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_LONG;
				bind[i].buffer_length = 4;
				bind[i].is_unsigned = true;
				break;
			case(BindType.ULong):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_LONGLONG;
				bind[i].buffer_length = 8;
				bind[i].is_unsigned = true;
				break;
			case(BindType.Float):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_FLOAT;
				bind[i].is_unsigned = false;
				break;
			case(BindType.Double):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_DOUBLE;
				bind[i].is_unsigned = false;
				break;
			case(BindType.String):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_STRING;
				bind[i].is_unsigned = false;
				break;
			case(BindType.Binary):
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_BLOB;
				bind[i].is_unsigned = false;
				break;
			//case(BindType.Date):
			//case(BindType.DateTime):
			case(BindType.Time):
				helper.time[i] = MYSQL_TIME();
				bind[i].buffer = &helper.time[i];
				bind[i].buffer_type = enum_field_types.MYSQL_TYPE_DATETIME;
				bind[i].is_unsigned = false;
				break;
			default:
				assert(false, "Unhandled bind type"); //TODO more detailed information;
			}
			
			bind[i].length = &helper.len[i];
			bind[i].error = &helper.error[i];
			bind[i].is_null = &helper.is_null[i];
		}
	}
	
	debug(Log)
	{
		static Logger log;
		static this()
		{
			log = Log.getLogger("dbi.mysql.MysqlPreparedStatement.MysqlPreparedStatement");
		}
		
		private void logError()
		{
			char* err = mysql_stmt_error(stmt);
			log.trace(toDString(err));
		}
	}
}

unittest
{
	Log.getRootLogger.addAppender(new ConsoleAppender);
	
	MysqlDatabase db = new MysqlDatabase();
	db.connect("dbname=test", "test", "test");
	auto provider = new MysqlPreparedStatementProvider(db);
	auto st = provider.prepare("SELECT * FROM test WHERE 1");
	assert(st);
	assert(st.getParamCount == 0);
	st.execute();
	auto metadata = st.getResultMetadata();
	foreach(f; metadata)
	{
		Stdout.formatln("Name:{}, Type:{}", f.name, f.type);
	}
	uint id;
	char[] name;
	DateTime dateofbirth;
	BindType[] resTypes;
	resTypes ~= BindType.UInt;
	resTypes ~= BindType.String;
	resTypes ~= BindType.Time;
	st.setResultTypes(resTypes);
	void*[] bind;
	bind.length = 3;
	bind[0] = &id;
	bind[1] = &name;
	bind[2] = &dateofbirth;
	assert(st.execute);
	assert(st.fetch(bind));
	Stdout.formatln("id:{},name:{},dateofbirth:{}",id,name,dateofbirth.year);
	assert(!st.fetch(bind));
	
	auto st2 = provider.prepare("SELECT * FROM test WHERE id = \?");
	assert(st2);
	BindType[] paramTypes;
	void*[] pBind;
	ushort usID = 1;
	paramTypes ~= BindType.UShort;
	st2.setParamTypes(paramTypes);
	st2.setResultTypes(resTypes);
	pBind ~= &usID;
	assert(st2.execute(pBind));
	assert(st2.fetch(bind));
	Stdout.formatln("id:{},name:{},dateofbirth:{}",id,name,dateofbirth.year);
}

}