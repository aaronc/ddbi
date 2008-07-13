module dbi.mysql.MysqlVirtualStatement;

version(Windows) {
	private import dbi.mysql.imp_win;
}
else {
	private import dbi.mysql.imp;
}

import tango.stdc.stringz : toDString = fromStringz, toCString = toStringz;
import dbi.VirtualBind, dbi.Database, dbi.DBIException;
import dbi.mysql.MysqlMetadata, dbi.mysql.MysqlError;

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
		exec(execSql);
	}
	
	private void exec(char[] execSql)
	{
		int error = mysql_real_query(mysql, toCString(execSql), execSql.length);
		if (error) {
		        throw new DBIException("Unable to execute a command on the MySQL database.", sql, error, specificToGeneral(error));
		}
		
		res = mysql_store_result(mysql);
		if (res !is null) {
			fields = mysql_fetch_fields(res);
			fieldCount = mysql_num_fields(res);
		}
	}
	
	bool fetch(void*[] bind, void* delegate(size_t) allocator = null)
	{
		assert(false);
		
		
		if(!res) return false;
		
		MYSQL_ROW row = mysql_fetch_row(res);
		uint* lengths = mysql_fetch_lengths(res);
		if (row is null) {
			return false;
		}
		if(lengths is null) {
			throw new DBIException;
		}
		
		assert(false, "Not implemented");
		for(uint index = 0; index < fieldCount; index++) {
		}
		
		foreach(i, type; resTypes)
		{
			with(BindType)
			{
				switch(type)
				{
				case Bool:
				case Byte:
					byte* ptr = cast(byte*)bind[i];
					break;
				case Short:
					short* ptr = cast(short*)bind[i];
					break;
				case Int:
					int* ptr = cast(int*)bind[i];
					break;
				case Long:
					long* ptr = cast(long*)bind[i];
					break;
				case UByte:
					ubyte* ptr = cast(ubyte*)bind[i];
					break;
				case UShort:
					ushort* ptr = cast(ushort*)bind[i];
					break;
				case UInt:
					uint* ptr = cast(uint*)bind[i];
					break;
				case ULong:
					ulong* ptr = cast(ulong*)bind[i];
					break;
				case Float:
					float* ptr = cast(float*)bind[i];
					break;
				case Double:
					double* ptr = cast(double*)bind[i];
					break;
				case String:
					char[]* ptr = cast(char[]*)bind[i];
					break;
				case Binary:
					void[]* ptr = cast(void[]*)bind[i];
					break;
				case Time:
				case DateTime:
				case Null:
				default:
					assert(false, "Not implemented");
					break;
				}
			}
		}
		
		return true;
	}
	
	void prefetchAll() { }
	
	void reset()
	{
		if (res !is null) {
			mysql_free_result(res);
			res = null;
			fields = null;
			fieldCount = 0;
		}
	}
	
	ulong getLastInsertID()
	{
		 return mysql_insert_id(mysql);
	}
	
	private:
		MYSQL* mysql;
		MYSQL_RES* res;
		MYSQL_FIELD* fields;
		uint fieldCount;
}