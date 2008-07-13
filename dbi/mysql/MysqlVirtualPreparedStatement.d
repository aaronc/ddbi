module dbi.mysql.MysqlVirtualPreparedStatement;

import dbi.mysql.MysqlDatabase;
import dbi.VirtualBind;

class MysqlVirtualStatement : VirtualStatement
{
	void execute()
	{
		exec(sql);
	}

	void execute(void*[] bind)
	{
		auto execSql = virtualBind(bind);
		exec(execSql);
	}
	
	private void exec(execSql)
	{
		int error = mysql_real_query(mysql, toCString(execSql), execSql.length);
		if (error) {
		        Cout("execute(): ");
		        Cout(toDString(mysql_error(connection)));
		        Cout("\n").flush;			
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
			throw new DBIExecption;
		}
		
		assert(false, "Not implemented")
		for (uint index = 0; index < fieldCount; index++) {
		}
		
		foreach(i, type; resTypes)
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
				execSql ~= Integer.toString(*ptr);
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
				void[]* ptr = cast(void[]**)bind[i];
				break;
			case Time:
			case DateTime:
			case Null:
			default:
				assert(false, "Not implemented");
				break;
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

	package this(MYSQL* mysql, char[] sql)
	{
		this.mysql = mysql;
		this.sql = sql;
	}
	
	private:
		MYSQL* mysql;
		char[] sql;
		MYSQL_RES* res;
		MYSQL_FIELD* fields;
		uint fieldCount;
}