module dbi.mysql.MysqlConvert;

import ConvertInteger = tango.text.convert.Integer;
import ConvertFloat = tango.text.convert.Float;
import tango.stdc.stringz : toDString = fromStringz, toCString = toStringz;
import DT = tango.time.Time, tango.time.Clock;
import tango.core.Traits;

import dbi.mysql.c.mysql;
import dbi.util.DateTime;

static void bindMysqlResField(Type)(char[] res, enum_field_types type, ref Type val, void* delegate(size_t) allocator = null)
{
	static if(isIntegerType!(Type) || isRealType!(Type) || is(Type == bool))
	{
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
	        	val = cast(Type)ConvertInteger.parse(res);
	        	break;
	        case MYSQL_TYPE_NEWDECIMAL:
			case MYSQL_TYPE_DECIMAL:
	        case MYSQL_TYPE_FLOAT:
	        case MYSQL_TYPE_DOUBLE:
	        	val = cast(Type)ConvertFloat.parse(res);
	        	break;
	        case MYSQL_TYPE_VAR_STRING:
	        case MYSQL_TYPE_STRING:
	        case MYSQL_TYPE_VARCHAR:
	        	static if(isIntegerType!(Type))
	        		val = cast(Type)ConvertInteger.parse(res);
	        	else static if(isRealType!(Type))
	        		val = cast(Type)ConvertFloat.parse(res);
	        	else static if(is(Type == bool)) {
	        		if(res == "true") val = true;
	        		else if(res == "false") val = false;
	        		else val = cast(Type)ConvertInteger.parse(res);
	        	}
	        	else static assert(false);
	        	break;
	        case MYSQL_TYPE_NULL:
	        	val = Type.init;
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
				val = Type.init;
	        	break;		
			}
		}
	}
	else static if(is(Type == char[]))
	{
		val = res;
	}
	else static if(is(Type == void[]) || is(Type == ubyte[]))
	{
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
				val = null;
	        	break;
	        case MYSQL_TYPE_NEWDECIMAL:
			case MYSQL_TYPE_DECIMAL:
	        case MYSQL_TYPE_FLOAT:
	        case MYSQL_TYPE_DOUBLE:
	        	debug assert(false, "Unsupported type");
	        	val = null;
	        	break;
	        case MYSQL_TYPE_ENUM:
	        case MYSQL_TYPE_VAR_STRING:
	        case MYSQL_TYPE_STRING:
	        case MYSQL_TYPE_VARCHAR:
	        	val = cast(ubyte[])res;
	        	break;
	        case MYSQL_TYPE_NULL:
	        	val = null;
	        	break;		
	        case MYSQL_TYPE_TINY_BLOB:
	        case MYSQL_TYPE_MEDIUM_BLOB:
	        case MYSQL_TYPE_LONG_BLOB:
	        case MYSQL_TYPE_BLOB:
	        	//strToBinary(res, *val);
	        	val = cast(ubyte[])res;
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
				val = null;
	        	break;
			}
		}
	}
	else static if(is(Type == DT.DateTime) || is(Type == DT.Time))
	{
		static if(is(Type == DT.DateTime))
			alias val dt;
		else static if(is(Type == DT.Time))
			DT.DateTime dt;
		else static assert(false);
		
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
		static if(is(Type == DT.Time)) {
			val = Clock.fromDate(dt);
		}
	}
	else static assert(false, "Unsupported MySql bind type " ~ Type.stringof);
}