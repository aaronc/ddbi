/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.PreparedStatement;

public import tango.group.time;

enum BindType : ubyte { Null, Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, String, Binary, Time, DateTime };

interface IPreparedStatement
{
	uint getParamCount();
	FieldInfo[] getResultMetadata();
	void setParamTypes(BindType[] paramTypes);
	void setResultTypes(BindType[] resTypes);
	void execute();
	void execute(void*[] bind);
	bool fetch(void*[] bind, void* delegate(size_t) allocator = null);
	void prefetchAll();
	void reset();
	ulong getLastInsertID();
}

struct FieldInfo
{
	char[] name;
	BindType type;
}

BindType getBindType(T)()
{
	static if(is(T == byte))
	{
	    return BindType.Byte;
	}
	else static if(is(T == ubyte))
	{
	    return BindType.UByte;
	}
	else static if(is(T == short))
	{
	    return BindType.Short;
	}
	else static if(is(T == ushort))
	{
	    return BindType.UShort;
	}
	else static if(is(T == int))
	{
	    return BindType.Int;
	}
	else static if(is(T == uint))
	{
	    return BindType.UInt;
	}
	else static if(is(T == long))
	{
	    return BindType.Long;
	}
	else static if(is(T == ulong))
	{
	    return BindType.ULong;
	}
	else static if (is(T == float))
	{
	    return BindType.Float;
	}
	else static if (is(T == double))
	{
	    return BindType.Double;
	}
	else static if (is(T == char[]))
	{
	    return BindType.String;
	}
	else static if (is(T == ubyte[]) || is(T == void[]))
	{
	    return BindType.Binary;
	}
	else static if (is(T == Time))
	{
	    return BindType.Time;
	}
	else static if (is(T == DateTime))
	{
	    return BindType.DateTime;
	}
	else return BindType.Null;
}

import dbi.Database;
import Integer = tango.text.convert.Integer;
import Float = tango.text.convert.Float;

class PreparedStatement //: IPreparedStatement
{
	this (Database database, char[] sql) {
		this.database = database;
		this.sql = sql;
		auto len = sql.length;
		for(size_t i = 0; i < len; ++i)
		{
			if(sql[i] == '\?')
				paramIndices ~= i;
		}
	}

	uint getParamCount()
	{
		return paramIndices.length;
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
		database.execute(sql);
	}
	
	void execute(void*[] bind)
	{
		auto sqlGen = database.sqlGen;
		
		size_t idx = 0;
		char[] execSql;
		foreach(i, type; paramTypes)
		{
			execSql ~= sql[idx .. paramIndices[i]];
			idx = paramIndices[i] + 1;
			switch(type)
			{
			case Bool:
				bool* ptr = cast(byte*)bind[i];
				if(*ptr) execSql ~= "1";
				else execSql ~= "0";
				break;
			case Byte:
				byte* ptr = cast(byte*)bind[i];
				execSql ~= Integer.toString(*ptr);
				break;
			case Short:
				short* ptr = cast(short*)bind[i];
				execSql ~= Integer.toString(*ptr);
				break;
			case Int:
				int* ptr = cast(int*)bind[i];
				execSql ~= Integer.toString(*ptr);
				break;
			case Long:
				long* ptr = cast(long*)bind[i];
				execSql ~= Integer.toString(*ptr);
				break;
			case UByte:
				ubyte* ptr = cast(ubyte*)bind[i];
				execSql ~= Integer.toString(*ptr);
				break;
			case UShort:
				ushort* ptr = cast(ushort*)bind[i];
				execSql ~= Integer.toString(*ptr);
				break;
			case UInt:
				uint* ptr = cast(uint*)bind[i];
				execSql ~= Integer.toString(*ptr);
				break;
			case ULong:
				ulong* ptr = cast(ulong*)bind[i];
				execSql ~= Integer.toString(*ptr);
				break;
			case Float:
				float* ptr = cast(float*)bind[i];
				execSql ~= Float.toString(*ptr);
				break;
			case Double:
				double* ptr = cast(double*)bind[i];
				execSql ~= Float.toString(*ptr);
				break;
			case String:
				char[]* ptr = cast(char[]*)bind[i];
				execSql ~= *ptr;
				assert(false, "String escaping");
				break;
			case Binary:
				ubyte[]* ptr = cast(void[]**)bind[i];
				execSql ~= sqlGen.createBinaryString(*ptr);
				break;
			case Time:
			case DateTime:
			case Null:
			default:
				assert(false, "Not implemented");
				break;
			}
		}
		execSql ~= sql[idx .. $];
		res = database.query(execSql);
	}
	
	bool fetch(void*[] bind, void* delegate(size_t) allocator = null)
	{
		void bindRow(Row row) {
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
		}		
		
		if(prefetchedRows.length) {
			if(prefetchedRowIdx < prefetchedRows.length) {
				bindRow(prefetchedRows[prefetchedRowIdx]);
				++prefetchedRowIdx;
				return true;
			}
			else {
				prefetchedRows = null;
				return false;
			}
		}
		else if(!res) return false;
		
		auto row = res.fetchRow;
		if(!row) {
			res = null;
			return false;
		}
		
		bindRow(row);
		
		return true;
	}
	
	void prefetchAll()
	{
		prefetchedRows = res.fetchAll;
		prefetchedRowIdx = 0;
	}
	
	void reset()
	{
		if(res) {
			res.finish;
			res = null;
		}
		prefetchedRows = null;
	}
	
	ulong getLastInsertID()
	{
		return database.getLastInsertID;
	}
	
	char[] getLastErrorMsg()
	{
		return database.getErrorMessage;
	}
	
	private:
		Database database;
		Result res;
		Rows[] prefetchedRows;
		size_t prefetchedRowIdx;
		char[] sql;
		size_t[] paramIndices;
		BindType[] paramTypes;
		BindType[] resTypes;
}


debug(UnitTest) {
unittest {
	auto st = PreparedStatement(null, "SELECT * FROM test WHERE id = ? and name = ?");
	assert(st.getParamCount == 2);
}
}
/+
class Statement : IPreparedStatement {
	/**
	 * Make a new instance of Statement.
	 *
	 * Params:
	 *	database = The database connection to use.
	 *	sql = The SQL code to prepare.
	 */
	this (Database database, char[] sql) {
		this.database = database;
		this.sql = sql;
	}

	/**
	 * Execute a SQL statement that returns no results.
	 */
	void execute () {
		database.execute(getSql());
	}
	
	uint getParamCount();
	FieldInfo[] getResultMetadata();
	void setParamTypes(BindType[] paramTypes);
	void setResultTypes(BindType[] resTypes);
	void execute();
	void execute(void*[] bind);
	bool fetch(void*[] bind);
	void prefetchAll();
	void reset();
	ulong getLastInsertID();
	char[] getLastErrorMsg();

	/**
	 * Query the database.
	 *
	 * Returns:
	 *	A Result object with the queried information.
	 */
	Result query () {
		return database.query(getSql());
	}

	private:
	Database database;
	char[] sql;
	char[][] binds;

	/**
	 * Escape a SQL statement.
	 *
	 * Params:
	 *	string = An unescaped SQL statement.
	 *
	 * Returns:
	 *	The escaped form of string.
	 */
	char[] escape (char[] string) {
		if (database !is null) {
			return database.escape(string);
		} else {
			char[] result;
			size_t count = 0;

			// Maximum length needed if every char is to be quoted
			result.length = string.length * 2;

			for (size_t i = 0; i < string.length; i++) {
				switch (string[i]) {
					case '"':
					case '\'':
					case '\\':
						result[count++] = '\\';
						break;
					default:
						break;
				}
				result[count++] = string[i];
			}

			result.length = count;
			return result;
		}
	}

	/**
	 * Replace every "?" in the current SQL statement with its bound value.
	 *
	 * Returns:
	 *	The current SQL statement with all occurences of "?" replaced.
	 *
	 * Todo:
	 *	Raise an exception if binds.length != count(sql, "?")
	 */
	char[] getSqlByQM () {
		char[] result;
		size_t i = 0, j = 0, count = 0;

		// binds.length is for the '', only 1 because we replace the ? too
		result.length = sql.length + binds.length;
		for (i = 0; i < binds.length; i++) {
			result.length = result.length + binds[i].length;
		}

		for (i = 0; i < sql.length; i++) {
			if (sql[i] == '?') {
				result[j++] = '\'';
				result[j .. j + binds[count].length] = binds[count];
				j += binds[count++].length;
				result[j++] = '\'';
			}
			else {
				result[j++] = sql[i];
			}
		}

		sql = result;
		return result;
	}

	/**
	 * Replace every ":name:" in the current SQL statement with its bound value.
	 *
	 * Returns:
	 *	The current SQL statement with all occurences of ":name:" replaced.
	 *
	 * Todo:
	 *	Raise an exception if binds.length != (count(sql, ":") * 2)
	 */
	char[] getSqlByFN () {
		char[] result = sql;
		version (Phobos) {
			ptrdiff_t beginIndex = 0, endIndex = 0;
			while ((beginIndex = std.string.find(result, ":")) != -1 && (endIndex = std.string.find(result[beginIndex + 1 .. length], ":")) != -1) {
				result = result[0 .. beginIndex] ~ "'" ~ getBoundValue(result[beginIndex + 1.. beginIndex + endIndex + 1]) ~ "'" ~ result[beginIndex + endIndex + 2 .. length];
			}
		} else {
			uint beginIndex = 0, endIndex = 0;
			while ((beginIndex = tango.text.Util.locate(result, ':')) != result.length && (endIndex = tango.text.Util.locate(result, ':', beginIndex + 1)) != result.length) {
				result = result[0 .. beginIndex] ~ "'" ~ getBoundValue(result[beginIndex + 1 .. endIndex]) ~ "'" ~ result[endIndex + 1 .. length];
			}
		}
		return result;
	}

	/**
	 * Replace all variables with their bound values.
	 *
	 * Returns:
	 *	The current SQL statement with all occurences of variables replaced.
	 */
	char[] getSql () {
		version (Phobos) {
			if (std.string.find(sql, "?") != -1) {
				return getSqlByQM();
			} else if (std.string.find(sql, ":") != -1) {
				return getSqlByFN();
			} else {
				return sql;
			}
		} else {
			if (tango.text.Util.contains(sql, '?')) {
				return getSqlByQM();
			} else if (tango.text.Util.contains(sql, ':')) {
				return getSqlByFN();
			} else {
				return sql;
			}
		}
	}

	/**
	 * Get the value bound to a ":name:".
	 *
	 * Params:
	 *	fn = The ":name:" to return the bound value of.
	 *
	 * Returns:
	 *	The bound value of fn.
	 *
	 * Throws:
	 *	DBIException if fn is not bound
	 */
	char[] getBoundValue (char[] fn) {
		for (size_t index = 0; index < bindsFNs.length; index++) {
			if (bindsFNs[index] == fn) {
				return binds[index];
			}
		}
		throw new DBIException(fn ~ " is not bound in the Statement.");
	}
}

debug(UnitTest) {
unittest {
	version (Phobos) {
		void s1 (char[] s) {
			std.stdio.writefln("%s", s);
		}

		void s2 (char[] s) {
			std.stdio.writefln("   ...%s", s);
		}
	} else {
		void s1 (char[] s) {
			tango.io.Stdout.Stdout(s).newline();
		}

		void s2 (char[] s) {
			tango.io.Stdout.Stdout("   ..." ~ s).newline();
		}
	}

	s1("dbi.Statement:");
	Statement stmt = new Statement(null, "SELECT * FROM people");
	char[] resultingSql = "SELECT * FROM people WHERE id = '10' OR name LIKE 'John Mc\\'Donald'";

	s2("escape");
	assert (stmt.escape("John Mc'Donald") == "John Mc\\'Donald");

	s2("simple sql");
	stmt = new Statement(null, "SELECT * FROM people");
	assert (stmt.getSql() == "SELECT * FROM people");

	s2("bind by '?'");
	stmt = new Statement(null, "SELECT * FROM people WHERE id = ? OR name LIKE ?");
	stmt.bind(1, "10");
	stmt.bind(2, "John Mc'Donald");
	assert (stmt.getSql() == resultingSql);

	/+
	s2("bind by '?' sent to getSql via variable arguments");
	stmt = new Statement("SELECT * FROM people WHERE id = ? OR name LIKE ?");
	assert (stmt.getSql("10", "John Mc'Donald") == resultingSql);
	+/

	s2("bind by ':fieldname:'");
	stmt = new Statement(null, "SELECT * FROM people WHERE id = :id: OR name LIKE :name:");
	stmt.bind("id", "10");
	stmt.bind("name", "John Mc'Donald");
	assert (stmt.getBoundValue("name") == "John Mc\\'Donald");
	assert (stmt.getSql() == resultingSql);
}
}
+/