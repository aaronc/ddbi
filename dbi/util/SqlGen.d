module dbi.util.SqlGen;

deprecated import tango.time.Time;
deprecated import tango.core.Traits;

public import dbi.model.Metadata;

deprecated import DT = dbi.util.DateTime;
deprecated import Integer = tango.text.convert.Integer;
import dbi.util.StringWriter;


interface SqlWriter
{
	SqlWriter start();
	SqlWriter start(SqlStringWriter);
	SqlWriter write(char[][] strs...);
	SqlWriter list(char[][] fields...);
	SqlWriter qlist(char[] qualifier, char[][] fields...);
	char[] get();
}

/**
 * Helper methods for generating database-specific SQL (without necessarily
 * knowing the specifics of that database's ways of quoting and escaping).
 * 
 */
abstract class SqlGenerator : SqlWriter
{
	SqlWriter start()
	{
		assert(writer_ !is null);
		writer_.reset;
		return this;
	}
	
	SqlWriter start(SqlStringWriter writer)
	{
		writer_ = writer;
		writer_.reset;
		return this;
	}
	private SqlStringWriter writer_;
	
	SqlWriter write(char[][] strs...)
	in { assert(writer_ !is null); }
	body {
		writer_(strs);
		return this;
	}
	
	SqlWriter list(char[][] identifiers...)
	in { assert(writer_ !is null); }
	body {
		char c = identifierQuoteChar;
		char[1] q = [c];
		char[2] qc = [c,','];
		foreach(id; identifiers)
			writer_(q,id,qc);
		writer_.backup;
		return this;
	}
	
	SqlWriter qlist(char[] qualifier, char[][] identifiers...)
	in { assert(writer_ !is null); }
	body {
		char c = identifierQuoteChar;
		char[1] q = [c];
		char[2] qc = [c,','];
		char[3] qdq = [c,'.',c];
		foreach(id; identifiers)
			writer_(q,qualifier,qdq,id,qc);
		writer_.backup;
		return this;
	}
	
	char[] get()
	in { assert(writer_ !is null); }
	body {
		return writer_.get;
	}
	
	char identifierQuoteChar()
	{
		return '"'; 
	}
	
	char stringQuoteChar()
	{
		return '\'';
	}
	
	char[] quoteColumnName(char[] colname)
	{
		auto quote = identifierQuoteChar;
		return quote ~ colname ~ quote;
	}
	
	char[] quoteTableName(char[] tablename)
	{
		auto quote = identifierQuoteChar;
		return quote ~ tablename ~ quote;
	}
	
	char[] getHexPrefix()
	{
		return "x'";
	}
	
	char[] getHexSuffix()
	{
		return "'";
	}
	
	/+char[] createBinaryString(ubyte[] binary)
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
	}+/
	
	char[] makeFieldList(char[][] fields)
	{
		return SqlGenHelper.makeFieldList(fields, identifierQuoteChar);
	}
	
	char[] makeQualifiedFieldList(char[] qualifier, char[][] fields)
	{
		return SqlGenHelper.makeQualifiedFieldList(qualifier, fields, identifierQuoteChar);
	}
	
	char[] makeInsertSql(char[] tablename, char[][] fields)
	{
		return SqlGenHelper.makeInsertSql(tablename, fields, identifierQuoteChar);
	}
	
	char[] makeUpdateSql(char[] whereClause, char[] tablename, char[][] fields)
	{
		return SqlGenHelper.makeUpdateSql(whereClause, tablename, fields, identifierQuoteChar);
	}
	
	char[] makeDeleteSql(char[] tablename, char[][] keyFields)
	{
		char[] res = "DELETE FROM ";
		res ~= quoteTableName(tablename);
		res ~= " WHERE ";
		auto len = keyFields.length;
		for(size_t i = 0; i < len; ++i)
		{
			if(i != 0) res ~= " AND ";
			res ~= quoteColumnName(keyFields[i]) ~ " = ?";
		}
		return res;
	}
	
	abstract char[] toNativeType(ColumnInfo info);
	
	char[] makeCreateSql(char[] tablename, ColumnInfo[] columnInfo, char[] options = null)
	{
		char[] res = "CREATE TABLE ";
		res ~= quoteTableName(tablename) ~ " (";
		auto len = columnInfo.length;
		for(size_t i = 0; i < len; ++i)
		{
			res ~= quoteColumnName(columnInfo[i].name) ~ " " ~ makeColumnDef(columnInfo[i], columnInfo);
			if(i != len - 1) res ~= ", ";
		}
		res ~= ")";
		
		if(options.length) res ~= " " ~ options;
		
		return res;
	}
	
/+	char[] makeCreateSql(TableSchema schema, char[] options = null)
	{
		char[] res = "CREATE TABLE ";
		res ~= quoteTableName(schema.tablename) ~ " (";
		auto len = schema.columnInfo.length;
		for(size_t i = 0; i < len; ++i)
		{
			res ~= quoteColumnName(schema.columnInfo[i].name) ~ " " ~ makeColumnDef(schema.columnInfo[i], columnInfo);
			if(i != len - 1) res ~= ", ";
		}
		res ~= ")";
		
		if(options.length) res ~= " " ~ options;
		
		return res;
	}+/
	
	
	char[] makeDropSql(char[] tablename, bool checkExists = true)
	{
		char[] res = "DROP TABLE ";
		if(checkExists) res ~= "IF EXISTS ";
		res ~= quoteTableName(tablename);
		return res;
	}
	
	char[] makeColumnDef(ColumnInfo info, ColumnInfo[] columnInfo)
	{
		char[] res = toNativeType(info);
		
		if(info.notNull)	res ~= " NOT NULL"; else res ~= " NULL";
		if(info.primaryKey) res ~= " PRIMARY KEY";
		if(info.autoIncrement) res ~= " AUTO_INCREMENT";
		
		return res;
	}
	
	char[] makeAddColumnSql(char[] tablename, ColumnInfo column)
	{
		return "ALTER TABLE " ~ quoteTableName(tablename) ~ " ADD COLUMN " 
		~ quoteColumnName(column.name) ~ " " ~ makeColumnDef(column, null);
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

debug(DBITest) {

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
	assert(sqlgen.identifierQuoteChar == '"');
	
	assert(SqlGenHelper.concatLists(
			sqlgen.makeQualifiedFieldList("user", ["name", "date"]),
			sqlgen.makeQualifiedFieldList("person", ["name", "date"])
			) == "\"user\".\"name\",\"user\".\"date\",\"person\".\"name\",\"person\".\"date\"");
	
	
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