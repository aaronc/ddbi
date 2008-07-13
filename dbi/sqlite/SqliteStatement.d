module dbi.sqlite.SqliteStatement;

import dbi.Statement, dbi.DBIException;
import tango.stdc.stringz : toDString = fromStringz, toCString = toStringz;
import tango.core.Traits;

import dbi.sqlite.imp;

class SqliteStatement : IStatement
{
	uint getParamCount()
	{
		return cast(uint)sqlite3_bind_parameter_count(stmt);
	}
	
	FieldInfo[] getResultMetadata()
	{
		auto fieldCount = sqlite3_column_count(stmt);
		FieldInfo[] fieldInfo;
		for(int i = 0; i < fieldCount; ++i)
		{
			FieldInfo info;
			
			info.name = toDString(sqlite3_column_name(stmt, i));
			info.type = fromSqliteType(sqlite3_column_type(stmt, i));
			
			fieldInfo ~= info;
		}
		
		return fieldInfo;
	}
	
	void setParamTypes(BindType[] paramTypes)
	{
		this.paramTypes = paramTypes;
	}
	
	void setResultTypes(BindType[] resTypes)
	{
		this.resTypes = resTypes;
	}
	
	void execute()
	{
		lastRes = sqlite3_step(stmt);
		wasReset = false;
		if(lastRes != SQLITE_ROW || lastRes != SQLITE_DONE)
			throw new DBIException;
	}
	
	void execute(void*[] ptrs)
	{
		auto len = paramTypes.length;
		if(ptrs.length != len) throw new DBIException;
		
		for(size_t i = 0; i < len; ++i)
		{
			bind!(true)(stmt, paramTypes[i], ptrs[i], i);
		}
		
		execute;
	}
	
	bool fetch(void*[] ptrs, void* delegate(size_t) allocator = null)
	{
		if(lastRes != SQLITE_ROW)
			return false;
		
		auto len = resTypes.length;
		if(ptrs.length != len) throw new DBIException;
		
		for(size_t i = 0; i < len; ++i)
		{
			bind!(false)(stmt, resTypes[i], ptrs[i], i);
		}
		
		lastRes = sqlite3_step(stmt);
		wasReset = false;
		return true;
	}
	
	static void bindT(T, bool P)(sqlite3_stmt* stmt, void* ptr, int index)
	{
		T* val = cast(T*)ptr;
		static if(isIntegerType!(T) || is(T == bool))
		{
			static if(is(Int == long) || is(Int == uint) || is(Int == ulong))
			{
				static if(P) sqlite3_bind_int64(stmt, index + 1, cast(long)*val);
				else *val = cast(T)sqlite3_column_int64(stmt, index);
			}
			else
			{
				static if(P) sqlite3_bind_int(stmt, index + 1, cast(int)*val);
				else *val = cast(T)sqlite3_column_int(stmt, index);
			}
		}
		else static if(isRealType!(T))
		{
			static if(P) sqlite3_bind_double(stmt, index + 1, cast(double)*val);
			else *val = cast(T)sqlite3_column_double(stmt, index);
		}
		else static if(is(T == char[]))
		{
			static if(P) sqlite3_bind_blob(stmt, index + 1, val.ptr, val.length, null);
			else {
				auto res = sqlite3_column_text(stmt, index);
				auto len = sqlite3_column_bytes(stmt, index);
				*val = res[0 .. len];
			}
		}
		else static if(is(T == void[]) || is(T == ubyte[]))
		{
			auto res = sqlite3_column_blob(stmt, index);
			auto len = sqlite3_column_bytes(stmt, index);
			*val = res[0 .. len];
		}
		else static assert(false, "Unsupported Sqlite bind type " ~ T.stringof);
	}
	
	static void bindNull(bool P)(sqlite3_stmt* stmt, int index)
	{
		static if(P) sqlite3_bind_null(stmt, index + 1);
	}
	
	static void bind(bool P)(sqlite3_stmt* stmt, BindType type, void* ptr, int index)
	{
		with(BindType)
		{
			switch(type)
			{
			case Bool:
				bindT!(bool, P)(stmt, ptr, index);
				break;
			case Byte:
				bindT!(byte, P)(stmt, ptr, index);
				break;
			case Short:
				bindT!(short, P)(stmt, ptr, index);
				break;
			case Int:
				bindT!(int, P)(stmt, ptr, index);
				break;
			case Long:
				bindT!(long, P)(stmt, ptr, index);
				break;
			case UByte:
				bindT!(ubyte, P)(stmt, ptr, index);
				break;
			case UShort:
				bindT!(ushort, P)(stmt, ptr, index);
				break;
			case UInt:
				bindT!(uint, P)(stmt, ptr, index);
				break;
			case ULong:
				bindT!(ulong, P)(stmt, ptr, index);
				break;
			case Float:
				bindT!(float, P)(stmt, ptr, index);
				break;
			case Double:
				bindT!(double, P)(stmt, ptr, index);
				break;
			case String:
				bindT!(char[], P)(stmt, ptr, index);
				break;
			case Binary:
				bindT!(void[], P)(stmt, ptr, index);
				break;
			case Time:
				assert(false, "Unhandled bind type Time");
				//bindT!(Time, P)(stmt, ptr, index);
				break;
			case DateTime:
				assert(false, "Unhandled bind type DateTime");
				//bindT!(DateTime, P)(stmt, ptr, index);
				break;
			case Null:
				bindNull!(P)(stmt, index);
			default:
				debug assert(false, "Unhandled bind type"); //TODO more detailed information;
				bindNull!(P)(stmt, index);
				break;
			}
		}
	}
	
	void prefetchAll()
	{
	}
	
	void reset()
	{
		if(!wasReset) {
			sqlite3_reset(stmt);
			wasReset = true;
			lastRes = SQLITE_DONE;
		}
	}
	
	ulong getLastInsertID()
	{
		long id = sqlite3_last_insert_rowid(sqlite);
		if(id == 0)	return 0;
		else return cast(ulong)id;
	}
	
	package this(sqlite3* sqlite, sqlite3_stmt* stmt)
	{
		this.sqlite = sqlite;
		this.stmt = stmt;
	}
	
	~this()
	{
		if (stmt !is null) {
			sqlite3_finalize(stmt);
			stmt = null;
		}
	}
	
	private int lastRes;
	private bool wasReset = false;
	private sqlite3* sqlite;
	private sqlite3_stmt* stmt;
	private BindType[] paramTypes;
	private BindType[] resTypes;
	
	static BindType fromSqliteType(int type)
	{
		with(BindType) {
			switch(type)
			{
			case SQLITE_INTEGER:
				return Long;
			case SQLITE_FLOAT:
				return Double;
            case SQLITE_TEXT:
            	return String;
            case SQLITE_BLOB:
            	return Binary;
            case SQLITE_NULL:
            	return Null;
			default:
				debug assert(false, "Unsupported type");
				return Null;
			}
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