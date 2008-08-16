module dbi.SqlGen;

import DT = dbi.util.DateTime;import DT = dbi.util.DateTime;
import Integer = tango.text.convert.Integer;
import tango.time.Time;
import tango.core.Traits;

public import dbi.BindType;

/**
 * Helper methods for generating database-specific SQL (without necessarily
 * knowing the specifics of that database's ways of quoting and escaping).
 * 
 */
abstract class SqlGenerator
{
	char getIdentifierQuoteCharacter()
	{
		return '"'; 
	}
	
	char[] quoteColumnName(char[] colname)
	{
		auto quote = getIdentifierQuoteCharacter;
		return quote ~ colname ~ quote;
	}
	
	char[] quoteTableName(char[] tablename)
	{
		auto quote = getIdentifierQuoteCharacter;
		return quote ~ tablename ~ quote;
	}
	
	char getStringQuoteCharacter()
	{
		return '\'';
	}
	
	char[] getHexPrefix()
	{
		return "x'";
	}
	
	char[] getHexSuffix()
	{
		return "'";
	}
	
	char[] createBinaryString(ubyte[] binary)
	{
		const char[] hexDigits = "0123456789abcdef";
		
		char[] res;
		
		auto len = binary.length;
		auto prefix = getHexPrefix; auto pLen = prefix.length;
		auto suffix = getHexSuffix; auto sLen = suffix.length;
		
		res.length = len * 2 + pLen + sLen;
		res[0 .. pLen] = prefix;
		
		auto ptr = res.ptr + pLen;
		for(size_t i = 0; i < len; ++i)
		{
			ubyte x = binary[i];
			//*ptr = hexDigits[x >>> 4];
			*ptr = hexDigits[x & 0xF];
			++ptr;
			//*ptr = hexDigits[x & 0xF];
			*ptr = hexDigits[x >>> 4];
			++ptr;
		}
		
		res[$ - sLen .. $] = suffix;
		
		return res;
	}
	
	char[] makeFieldList(char[][] fields)
	{
		return SqlGenHelper.makeFieldList(fields, getIdentifierQuoteCharacter);
	}
	
	char[] makeQualifiedFieldList(char[] qualifier, char[][] fields)
	{
		return SqlGenHelper.makeQualifiedFieldList(qualifier, fields, getIdentifierQuoteCharacter);
	}
	
	char[] makeInsertSql(char[] tablename, char[][] fields)
	{
		return SqlGenHelper.makeInsertSql(tablename, fields, getIdentifierQuoteCharacter);
	}
	
	char[] makeUpdateSql(char[] whereClause, char[] tablename, char[][] fields)
	{
		return SqlGenHelper.makeUpdateSql(whereClause, tablename, fields, getIdentifierQuoteCharacter);
	}
	
	
	abstract char[] toNativeType(ColumnInfo info);
	
	char[] makeCreateSql(char[] tablename, ColumnInfo[] columnInfo, char[] options = null)
	{
		char[] res = "CREATE TABLE ";
		res ~= quoteTableName(tablename) ~ " (";
		auto len = columnInfo.length;
		for(size_t i = 0; i < len; ++i)
		{
			res ~= quoteColumnName(columnInfo[i].name) ~ " " ~ makeColumnDef(columnInfo[i]);
			if(i != len - 1) res ~= ", ";
		}
		res ~= ")";
		
		if(options.length) res ~= " " ~ options;
		
		return res;
	}
	
	char[] makeColumnDef(ColumnInfo info)
	{
		char[] res = toNativeType(info);
		
		if(info.notNull)	res ~= " NOT NULL"; else res ~= " NULL";
		if(info.primaryKey) res ~= " PRIMARY KEY";
		if(info.autoIncrement) res ~= " AUTO_INCREMENT";
		
		return res;
	}
	
	//char[] makeDeleteSql(char[] tablename, char[] whereClause);
	
	/+
	
	
		
	
	
	void makeAddColumnSql(char[] tablename, ColumnInfo column)
	{
		return "ALTER TABLE " ~ quoteTableName(tablename) ~ " ADD COLUMN " ~ makeColumnDef(column);
	}
	
	
	
	+/
	
	char[] printDateTime(DateTime dt, char[] res)
	{
		return DT.printDateTime(dt, res);
	}
	
	char[] printDate(DateTime dt, char[] res)
	{
		return DT.printDate(dt, res);
	}
	
	char[] printTime(DateTime dt, char[] res)
	{
		return DT.printTime(dt, res);
	}
	
	/**
	 * Escape a _string using the database's native method, if possible.
	 *
	 * Params:
	 *	src = The _string to escape,
	 *  dest = A destination buffer - length should be src.length * 2 + 1
	 *  (allows for the possibility that every character must be quoted + a null terminator).
	 *
	 * Returns:
	 *	The escaped _string.
	 */
	char[] escape(char[] src, char[] dest = null)
	{
		if(!dest.length || dest.length < src.length * 2)
			// Maximum length needed if every char is to be quoted
			dest.length = src.length * 2;
		
		size_t count = 0;

		for (size_t i = 0; i < src.length; i++) {
			switch (src[i]) {
				case '"':
				case '\'':
				case '\\':
					dest[count++] = '\\';
					break;
				default:
					break;
			}
			dest[count++] = src[i];
		}

		return dest[0 .. count];
	}
}

struct ColumnInfo
{
	char[] name;
	BindType type;
	bool notNull;
	bool autoIncrement;
	bool primaryKey;
	ulong limit;
}


class SqlGenHelper
{
	static char[] makeFieldList(char[][] items, char quote = '"')
	{
		
		char[] res;
		
		foreach(x; items)
		{
			res ~= quote ~ x ~ quote ~ ",";
		}
		
		return res[0 .. $ - 1];
	}
	
	static char[] makeQualifiedFieldList(char[] qualifier, char[][] items, char quote = '"')
	{
		char[] res;
		
		foreach(x; items)
		{
			res ~=  quote ~ qualifier ~ quote ~ "." ~ quote ~ x ~ quote ~ ",";
		}
		
		return res[0 .. $ - 1];
	}
	
	static char[] concatLists(char[] list1, char[] list2)
	{
		return list1 ~ "," ~ list2;
	}
	
	static char[] makeInsertSql(char[] tablename, char[][] items, char quote = '"')
	{
		if(!items.length) throw new Exception("Trying to make INSERT SQL but no fields were provided");
		
		char[] res = "INSERT INTO " ~ quote ~ tablename ~ quote ~ " (";
		res ~= makeFieldList(items, quote) ~ ") VALUES(";
		auto len = items.length;
		for(uint i = 0; i < len; ++i)
		{
			res ~= "?,";
		}
		res[$ - 1] = ')';
		return res;
	}

	static char[] makeUpdateSql(char[] whereClause, char[] tablename, char[][] fields, char quote = '"')
	{
		if(!fields.length) throw new Exception("Trying to make INSERT SQL but no fields were provided");
		
		char[] res = "UPDATE " ~ quote ~ tablename ~ quote ~ " SET ";
		foreach(f; fields)
		{
			res ~= quote ~ f ~ quote ~ "=\?,";
		}
		res[$-1] = ' ';
		if(whereClause.length) res ~= whereClause;
		return res;
	}
}

abstract class Serializer
{
	void add(T)(char[] fieldname, T value)
	{
		static if(is(T == bool))
		{
			
		}
		else static if(is(T == char[]))
		{
			
		}
		else static if(isIntegerType!(T))
		{
			
		}
		else static if(isRealType!(T))
		{
			
		}
		else static if(is(T == void[]) || is(T == ubyte[]))
		{
			
		}
		else static if(is(T == Time))
		{
			
		}
		else static if(is(T == DateTime))
		{
			
		}
		/+
		else static if(is(T == Date))
		{
			
		}
		else static if(is(T == TimeOfDay))
		{
			
		}		
		+/
		else static assert(false, "Unsupported serialization type " ~ T.stringof);
	}
	
	abstract protected void addValue(char[] fieldname, char[] value);
	
	abstract bool execute();  
}

debug(UnitTest) {

class TestSqlGen : SqlGenerator
{
	char[] toNativeType(ColumnInfo info)
	{
		return null;
	}
}
	
unittest
{
	auto sqlgen = new TestSqlGen;
	assert(sqlgen.makeFieldList(["name", "date"]) == "\"name\",\"date\"");
	assert(sqlgen.makeQualifiedFieldList("user", ["name", "date"]) == "\"user\".\"name\",\"user\".\"date\"");
	auto res = sqlgen.makeInsertSql("user", ["name", "date"]);
	assert(res == "INSERT INTO \"user\" (\"name\",\"date\") VALUES(?,?)", res);
	res = sqlgen.makeUpdateSql("WHERE 1", "user", ["name", "date"]);
	assert(res == "UPDATE \"user\" SET \"name\"=?,\"date\"=? WHERE 1", res);
	assert(sqlgen.getIdentifierQuoteCharacter == '"');
	
	assert(SqlGenHelper.concatLists(
			sqlgen.makeQualifiedFieldList("user", ["name", "date"]),
			sqlgen.makeQualifiedFieldList("person", ["name", "date"])
			) == "\"user\".\"name\",\"user\".\"date\",\"person\".\"name\",\"person\".\"date\"");
	
	ulong x = 0x57a60e9fe4321b0;
	auto ptr = cast(ubyte*)&x;
	auto binStr = sqlgen.createBinaryString(ptr[0 .. 8]);
	version(LittleEndian) {
		assert(binStr == "x'0b1234ef9e06a750'", binStr);
	}
	else {
		assert(binStr == "x'057a60e9fe4321b0'", binStr);
	}
	
	//DateTime
	
	DT.DateTime dt;
	dt.date.year = 2008;
	dt.date.month = 1;
	dt.date.day = 15;

	res = new char[19];
	
	res = sqlgen.printDateTime(dt, res);
	assert(res == "2008-01-15 00:00:00", res);
	
	dt.time.hours = 3;
	dt.time.minutes = 15;
	dt.time.seconds = 47;
	
	res = sqlgen.printDateTime(dt, res);
	assert(res == "2008-01-15 03:15:47", res);
}
}