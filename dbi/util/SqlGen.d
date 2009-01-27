module dbi.util.SqlGen;

deprecated import Integer = tango.text.convert.Integer;

public import dbi.model.Metadata;
import dbi.util.StringWriter;

/**
 * Helper methods for generating database-specific SQL (without necessarily
 * knowing the specifics of that database's ways of quoting and escaping).
 * 
 */
abstract class SqlGenerator
{
	/**
	 * 
	 */
	char identifierQuoteChar()
	{
		return '"'; 
	}
	
	/**
	 * 
	 */
	char stringQuoteChar()
	{
		return '\'';
	}
	
	/**
	 * 
	 */
	abstract char[] toNativeType(ColumnInfo info);
	
	/**
	 * Starts chained writing - used together with
	 * the write, list, and qlist method as a convenient way
	 * of dynamically generating sql.
	 * 
	 * Example:
	 * ---
	 * 	auto writer = new SqlStringWriter;
	 * 	auto sql = db.sqlGen.start(writer)("SELECT ").list("name","date")
	 * 	(" FROM ").id("user")("WHERE ").id("id")("=?").get;
	 * ---
	 */
	final SqlGenerator start(SqlStringWriter writer = null)
	{
		if(writer !is null) writer_ = writer;
		else assert(writer_ !is null);
		writer_.reset;
		return this;
	}
	private SqlStringWriter writer_;
	
	/**
	 * 
	 */
	final SqlGenerator write(char[][] strs...)
	in { assert(writer_ !is null); }
	body {
		writer_(strs);
		return this;
	}
	
	/**
	 * Alias for write
	 */
	alias write opCall;
	
	/**
	 * Writes a list of quoted identifiers
	 */
	final SqlGenerator list(char[][] identifiers...)
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
	
	/**
	 * Alias for list - for quoting a single identifier
	 */
	alias list id;
	
	/**
	 * Writes a list of quoted, qualified identifiers.
	 * 
	 * Should be very useful for doing join queries.
	 * 
	 * Example:
	 * ---
	 * qlist("user","name","date") // generates "user"."name","user"."date"
	 * ---
	 */
	final SqlGenerator qlist(char[] qualifier, char[][] identifiers...)
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
	
	/**
	 * Alias for qlist - for quoting a single qualified identifier
	 */
	alias qlist qid;
	/+
	final SqlGenerator fieldExpr(char[] fieldname, char[] expr)
	in { assert(writer_ !is null); }
	body {
		char c = identifierQuoteChar;
		char[1] q = [c];
		writer_(q,fieldname,q,expr);
		return this;
	}+/
	
	/**
	 * Returns: the sql that has been written
	 */
	final char[] get()
	in { assert(writer_ !is null); }
	body {
		return writer_.get;
	}
	
	/**
	 * 
	 */
	char[] makeInsertSql(SqlStringWriter writer, char[] tablename, char[][] fields...)
	{
		start(writer);
		writer_("INSERT INTO ");
		id(tablename);
		writer_(" (");
		list(fields);
		writer_(") VALUES(");
		foreach(f;fields) writer_("?,");
		return writer_.correct(')').get;
	}
	
	/**
	 * 
	 */
	char[] makeUpdateSql(SqlStringWriter writer, char[] tablename, char[] whereClause, char[][] fields...)
	{
		char c = identifierQuoteChar;
		char[1] q = [c];
		char[4] hmm = [c,'=','?',','];
		start(writer);
		writer_("UPDATE ");
		id(tablename);
		writer_(" SET ");
		foreach(f;fields) writer_(q,f,hmm);
		return writer_.correct(' ')(whereClause).get;
	}
	
	/**
	 * 
	 */
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
	
	/**
	 * 
	 */
	char[] makeAddColumnSql(char[] tablename, ColumnInfo column)
	{
		return "ALTER TABLE " ~ quoteTableName(tablename) ~ " ADD COLUMN " 
		~ quoteColumnName(column.name) ~ " " ~ makeColumnDef(column, null);
	}
	
	/**
	 * 
	 */
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

	char[] makeFieldList(char[][] fields)
	{
		return SqlGenHelper.makeFieldList(fields, identifierQuoteChar);
	}
	
	char[] makeQualifiedFieldList(char[] qualifier, char[][] fields)
	{
		return SqlGenHelper.makeQualifiedFieldList(qualifier, fields, identifierQuoteChar);
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
	auto writer = new SqlStringWriter;
	
	assert(sqlgen.identifierQuoteChar == '"');
	
	char[] res;
	res = sqlgen.makeInsertSql(writer,"user",["name","date"]);
	assert(res == `INSERT INTO "user" ("name","date") VALUES(?,?)`, res);
	
	res = sqlgen.makeUpdateSql(writer,"user","WHERE 1",["name", "date"]);
	assert(res == "UPDATE \"user\" SET \"name\"=?,\"date\"=? WHERE 1", res);
	
	assert(sqlgen.makeFieldList(["name", "date"]) == "\"name\",\"date\"");
	assert(sqlgen.makeQualifiedFieldList("user", ["name", "date"]) == "\"user\".\"name\",\"user\".\"date\"");
	
	assert(sqlgen.makeQualifiedFieldList("user", ["name", "date"]) ~ "," ~
			sqlgen.makeQualifiedFieldList("person", ["name", "date"])
			 == "\"user\".\"name\",\"user\".\"date\",\"person\".\"name\",\"person\".\"date\"");
	
	
	//DateTime
}
}