module dbi.SqlGen;

import Integer = tango.text.convert.Integer;

/*
 * Does a fixed-length 2-character ubyte to hex conversion.
 *
 */
void ubyteToHexFixed(ubyte x, char* res)
{
	const char[] digits = "0123456789abcdef";
	res[0] = digits[x & 0xF];
	x >>>= 4;
	res[1] = digits[x];
	return res;
}

class SqlGenerator
{
	char getIdentifierQuoteCharacter()
	{
		return '"'; 
	}
	
	char[] createBinaryString(ubyte[] binary)
	{
		char[] res;
		auto len = binary.length;
		res.length = len * 2 + 3;
		res[0 .. 2] = "x'";
		auto ptr = res.ptr + 2;
		for(size_t i = 0; i < len; ++i)
		{
			//assert(false, ubyteToHexFixed(binary[i]));
			//res[i * 2 + 2 .. i * 2 + 4] = ubyteToHexFixed(binary[i]);
			ubyteToHexFixed(binary[i], ptr);
			ptr += 2;
		}
		res[$ - 1] = '\'';
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

debug(UnitTest) {

unittest
{
	auto sqlgen = new SqlGenerator;
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
	
	ulong x = 0x57a60e9;
	auto ptr = cast(ubyte*)&x;
	auto binStr = sqlgen.createBinaryString(ptr[0 .. 8]);
	version(LittleEndian) {
		assert(binStr == "x'9e06a75000000000'", binStr);
	}
	else {
		assert(binStr == "x'00000000057a60e9'", binStr);
	}
	
}
}