module dbi.mysql.MysqlVirtualStatement;

version(Windows) {
	private import dbi.mysql.imp_win;
}
else {
	private import dbi.mysql.imp;
}

import tango.stdc.stringz : toDString = fromStringz, toCString = toStringz;
import DT = tango.time.Time, tango.time.Clock;
import ConvertInteger = tango.text.convert.Integer;
import ConvertFloat = tango.text.convert.Float;
import tango.core.Traits;
debug import tango.io.Stdout;

import dbi.VirtualStatement, dbi.Database, dbi.DBIException;
import dbi.mysql.MysqlMetadata, dbi.mysql.MysqlError;
import dbi.util.DateTime;

import dbi.util.StringWriter;

class MysqlVirtualStatement : VirtualStatement
{
	package this(char[] sql, SqlGenerator sqlGen, MYSQL* mysql)
	{
		super(sql, sqlGen);
		this.mysql = mysql;
	}
	
	uint getParamCount()
	{
		return paramIndices.length;
	}
	
	FieldInfo[] getResultMetadata()
	{
		if(fields is null) return null;

		return getFieldMetadata(fields[0..fieldCount]);
	}
	
	void execute()
	{
		exec(sql);
	}

	void execute(void*[] bind)
	{
		auto execSql = virtualBind_(bind);
		debug Stdout.formatln("Virtual Bind SQL: {}", execSql.get);
		exec(execSql.get);
		scope(exit) execSql.free;
	}
	
	private void exec(char[] sql)
	{
		int error = mysql_real_query(mysql, sql.ptr, sql.length);
		if (error) {
		        throw new DBIException("mysql_real_query error: " ~ toDString(mysql_error(mysql)), sql, error, specificToGeneral(error));
		}
		
		res = mysql_store_result(mysql);
		if (res !is null) {
			fields = mysql_fetch_fields(res);
			fieldCount = mysql_num_fields(res);
		}
	}
	
	static void bindResT(T)(char[] res, enum_field_types type, void* ptr)
	{
		static if(isIntegerType!(T) || isRealType!(T) || is(T == bool))
		{
			T* val = cast(T*)ptr;
			with(enum_field_types) {
				switch(type)
				{
				case MYSQL_TYPE_BIT:
				case MYSQL_TYPE_TINY:
		        case MYSQL_TYPE_SHORT:
		        case MYSQL_TYPE_LONG:
		        case MYSQL_TYPE_INT24:
		        case MYSQL_TYPE_LONGLONG:
		        case MYSQL_TYPE_YEAR:
		        case MYSQL_TYPE_ENUM:
		        	*val = cast(T)ConvertInteger.parse(res);
		        	break;
		        case MYSQL_TYPE_NEWDECIMAL:
				case MYSQL_TYPE_DECIMAL:
		        case MYSQL_TYPE_FLOAT:
		        case MYSQL_TYPE_DOUBLE:
		        	*val = cast(T)ConvertFloat.parse(res);
		        	break;
		        case MYSQL_TYPE_VAR_STRING:
		        case MYSQL_TYPE_STRING:
		        case MYSQL_TYPE_VARCHAR:
		        	static if(isIntegerType!(T))
		        		*val = cast(T)ConvertInteger.parse(res);
		        	else static if(isRealType!(T))
		        		*val = cast(T)ConvertFloat.parse(res);
		        	else static if(is(T == bool)) {
		        		if(res == "true") *val = true;
		        		else if(res == "false") *val = false;
		        		else *val = cast(T)ConvertInteger.parse(res);
		        	}
		        	else static assert(false);
		        	break;
		        case MYSQL_TYPE_NULL:
		        	*val = T.init;
		        	break;		
		        case MYSQL_TYPE_TINY_BLOB:
		        case MYSQL_TYPE_MEDIUM_BLOB:
		        case MYSQL_TYPE_LONG_BLOB:
		        case MYSQL_TYPE_BLOB:
		        	debug assert(false, "Not implemented");
		           	break;
		        case MYSQL_TYPE_TIMESTAMP:
		        case MYSQL_TYPE_DATE:
		        case MYSQL_TYPE_TIME:
		        case MYSQL_TYPE_DATETIME:
		        case MYSQL_TYPE_NEWDATE:
		        case MYSQL_TYPE_SET:
				case MYSQL_TYPE_GEOMETRY:
				default:
					debug assert(false, "Unsupported type");
					*val = T.init;
		        	break;		
				}
			}
		}
		else static if(is(T == char[]))
		{
			T* val = cast(T*)ptr;
			*val = res;
		}
		else static if(is(T == void[]) || is(T == ubyte[]))
		{
			ubyte[]* val = cast(ubyte[]*)ptr;
			with(enum_field_types) {
				switch(type)
				{
				case MYSQL_TYPE_BIT:
				case MYSQL_TYPE_TINY:
		        case MYSQL_TYPE_SHORT:
		        case MYSQL_TYPE_LONG:
		        case MYSQL_TYPE_INT24:
		        case MYSQL_TYPE_LONGLONG:
		        case MYSQL_TYPE_YEAR:
		        	debug assert(false, "Unsupported type");
					*val = null;
		        	break;
		        case MYSQL_TYPE_NEWDECIMAL:
				case MYSQL_TYPE_DECIMAL:
		        case MYSQL_TYPE_FLOAT:
		        case MYSQL_TYPE_DOUBLE:
		        	debug assert(false, "Unsupported type");
		        	*val = null;
		        	break;
		        case MYSQL_TYPE_ENUM:
		        case MYSQL_TYPE_VAR_STRING:
		        case MYSQL_TYPE_STRING:
		        case MYSQL_TYPE_VARCHAR:
		        	*val = cast(ubyte[])res;
		        	break;
		        case MYSQL_TYPE_NULL:
		        	*val = null;
		        	break;		
		        case MYSQL_TYPE_TINY_BLOB:
		        case MYSQL_TYPE_MEDIUM_BLOB:
		        case MYSQL_TYPE_LONG_BLOB:
		        case MYSQL_TYPE_BLOB:
		        	//strToBinary(res, *val);
		        	*val = cast(ubyte[])res;
		           	break;
		        case MYSQL_TYPE_TIMESTAMP:
		        case MYSQL_TYPE_DATE:
		        case MYSQL_TYPE_TIME:
		        case MYSQL_TYPE_DATETIME:
		        case MYSQL_TYPE_NEWDATE:
		        case MYSQL_TYPE_SET:
				case MYSQL_TYPE_GEOMETRY:
				default:
					debug assert(false, "Unsupported type");
					*val = null;
		        	break;
				}
			}
		}
		else static if(is(T == DT.DateTime) || is(T == DT.Time))
		{
			DT.DateTime dt;
			with(enum_field_types) {
				switch(type)
				{
		        case MYSQL_TYPE_DATE:
		        	parseDateFixed(res, dt.date);
					break;
		        case MYSQL_TYPE_TIME:
		        	parseTimeFixed(res, dt.time);
		        	break;
		        case MYSQL_TYPE_TIMESTAMP:
		        case MYSQL_TYPE_DATETIME:
		        	parseDateTime(res, dt);
		        	break;
		        case MYSQL_TYPE_NEWDATE:
		        	break;
				default:
					debug assert(false, "Unsupported type");
		        	break;
				}
			}
			static if(is(T == DT.DateTime))
				*(cast(DT.DateTime*)ptr) = dt;
			else static if(is(T == DT.Time)) {
				*(cast(DT.Time*)ptr) = Clock.fromDate(dt);
			}
			else static assert(false);
		}
		else static assert(false, "Unsupported MySql bind type " ~ T.stringof);
	}
	
	static void bindRes(char[] res, enum_field_types type, void* ptr, BindType bindType)
	{
		with(BindType)
		{
			switch(bindType)
			{
			case Bool:
				bindResT!(bool)(res, type, ptr);
				break;
			case Byte:
				bindResT!(byte)(res, type, ptr);
				break;
			case Short:
				bindResT!(short)(res, type, ptr);
				break;
			case Int:
				bindResT!(int)(res, type, ptr);
				break;
			case Long:
				bindResT!(long)(res, type, ptr);
				break;
			case UByte:
				bindResT!(ubyte)(res, type, ptr);
				break;
			case UShort:
				bindResT!(ushort)(res, type, ptr);
				break;
			case UInt:
				bindResT!(uint)(res, type, ptr);
				break;
			case ULong:
				bindResT!(ulong)(res, type, ptr);
				break;
			case Float:
				bindResT!(float)(res, type, ptr);
				break;
			case Double:
				bindResT!(double)(res, type, ptr);
				break;
			case String:
				bindResT!(char[])(res, type, ptr);
				break;
			case Binary:
				bindResT!(void[])(res, type, ptr);
				break;
			case Time:
				bindResT!(DT.Time)(res, type, ptr);
				break;
			case DateTime:
				bindResT!(DT.DateTime)(res, type, ptr);
				break;
			case Null:
				break;
			default:
				assert(false, "Unsupported bind type");
				break;
			}
		}
	}
	
	bool fetch(void*[] ptrs, void* delegate(size_t) allocator = null)
	{
		if(!res) return false;
		
		MYSQL_ROW row = mysql_fetch_row(res);
		uint* lengths = mysql_fetch_lengths(res);
		if (row is null) {
			return false;
		}
		
		if(lengths is null) {
			return false;
			//TODO throw new DBIException;
		}
		
		auto len = fieldCount;
		if(fieldCount != resTypes.length)
			return false;
			//TODO throw new DBIException();
		
		for(uint i = 0; i < len; ++i)
		{
			bindRes(row[i][0 .. lengths[i]], fields[i].type, ptrs[i], resTypes[i]);
		}
		
		return true;
	}
	
	void prefetchAll() { }
	
	ulong getLastInsertID()
	{
		 return mysql_insert_id(mysql);
	}
	
	void reset()
	{
		if (res !is null) {
			mysql_free_result(res);
			res = null;
			fields = null;
			fieldCount = 0;
		}
	}
	
	void close()
	{
		
	}
	
	private:
		MYSQL* mysql;
		MYSQL_RES* res;
		MYSQL_FIELD* fields;
		uint fieldCount;
}

void strToBinary(char[] str, ref ubyte[] bin)
{
	//debug Stdout.formatln("Converting binary string:{}", str);
	
	auto resLen = str.length / 2;
	debug assert((cast(double)resLen) == str.length / 2);
	bin.length = resLen;
	for(size_t i = 0; i < resLen; ++i)
	{
		bin[i] = ConvertInteger.parse(str[i * 2 .. i * 2 + 1], 16);
	}
}