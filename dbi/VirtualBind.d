module dbi.VirtualBind;

import dbi.Database;

import ConvertInteger = tango.text.convert.Integer;
import ConvertFloat = tango.text.convert.Float;
import T = tango.time.Time, tango.time.Clock;

import dbi.util.StringWriter;

abstract class VirtualStatement : IStatement {
	this (char[] sql, SqlGenerator sqlGen) {
		this.sqlGen = sqlGen;
		this.sql = sql;
		this.paramIndices = getParamIndices(sql);
		this.execSql = new DisposableStringWriter(sql.length * 2);
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
	
	protected IDisposableString virtualBind_(void*[] ptrs)
	{
		virtualBind(sql, paramIndices, paramTypes, ptrs, sqlGen, execSql);
		return execSql;
	}
	
	protected:
		DisposableStringWriter execSql;
		SqlGenerator sqlGen;
		char[] sql;
		size_t[] paramIndices;
		BindType[] paramTypes;
		BindType[] resTypes;
}

size_t[] getParamIndices(char[] sql) {
	size_t[] paramIndices;
	auto len = sql.length;
	for(size_t i = 0; i < len; ++i)
	{
		if(sql[i] == '\?')
			paramIndices ~= i;
	}
	return paramIndices;
}

void virtualBind(char[] sql, BindType[] paramTypes, void*[] ptrs, SqlGenerator sqlGen, DisposableStringWriter execSql)
{
	auto paramIndices = getParamIndices(sql);
	return virtualBind(sql, paramIndices, paramTypes, ptrs, sqlGen, execSql);
}

void virtualBind(char[] sql, size_t[] paramIndices, BindType[] paramTypes, void*[] ptrs, SqlGenerator sqlGen, DisposableStringWriter execSql)
{
	execSql.reset;
	
	size_t idx = 0;
	char stringQuoteChar = sqlGen.getStringQuoteCharacter;
	foreach(i, type; paramTypes)
	{
		execSql ~= sql[idx .. paramIndices[i]];
		idx = paramIndices[i] + 1;
		with(BindType)
		{
			switch(type)
			{
			case Bool:
				bool* ptr = cast(bool*)ptrs[i];
				if(*ptr) execSql ~= "1";
				else execSql ~= "0";
				break;
			case Byte:
				byte* ptr = cast(byte*)ptrs[i];
				execSql ~= ConvertInteger.toString(*ptr);
				break;
			case Short:
				short* ptr = cast(short*)ptrs[i];
				execSql ~= ConvertInteger.toString(*ptr);
				break;
			case Int:
				int* ptr = cast(int*)ptrs[i];
				execSql ~= ConvertInteger.toString(*ptr);
				break;
			case Long:
				long* ptr = cast(long*)ptrs[i];
				execSql ~= ConvertInteger.toString(*ptr);
				break;
			case UByte:
				ubyte* ptr = cast(ubyte*)ptrs[i];
				execSql ~= ConvertInteger.toString(*ptr);
				break;
			case UShort:
				ushort* ptr = cast(ushort*)ptrs[i];
				execSql ~= ConvertInteger.toString(*ptr);
				break;
			case UInt:
				uint* ptr = cast(uint*)ptrs[i];
				execSql ~= ConvertInteger.toString(*ptr);
				break;
			case ULong:
				ulong* ptr = cast(ulong*)ptrs[i];
				execSql ~= ConvertInteger.toString(*ptr);
				break;
			case Float:
				float* ptr = cast(float*)ptrs[i];
				execSql ~= ConvertFloat.toString(*ptr);
				break;
			case Double:
				double* ptr = cast(double*)ptrs[i];
				execSql ~= ConvertFloat.toString(*ptr);
				break;
			case String:
				char[]* ptr = cast(char[]*)ptrs[i];
				execSql ~= stringQuoteChar ~ simpleEscape(*ptr) ~ stringQuoteChar;
				//assert(false, "String escaping");
				break;
			case Binary:
				ubyte[]* ptr = cast(ubyte[]*)ptrs[i];
				execSql ~= sqlGen.createBinaryString(*ptr);
				break;
			case Time:
				T.Time* ptr = cast(T.Time*)ptrs[i];
				auto dt = Clock.toDate(*ptr);
				execSql ~= stringQuoteChar;
				auto res = execSql.getWriteBuffer(19);
				sqlGen.printDateTime(dt, res);
				execSql ~= stringQuoteChar;
				break;
			case DateTime:
				T.DateTime* ptr = cast(T.DateTime*)ptrs[i];
				execSql ~= stringQuoteChar;
				auto res = execSql.getWriteBuffer(19);
				sqlGen.printDateTime(*ptr, res);
				execSql ~= stringQuoteChar;
				break;
			case Null:
			default:
				assert(false, "Not implemented");
				break;
			}
		}
	}
	execSql ~= sql[idx .. $];
}

char[] simpleEscape(char[] string)
{
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

debug(UnitTest)
{
import dbi.DateTime;	

unittest
{
	auto sql = "select * from user where name = ? and birthday = ?";
	auto pIndices = getParamIndices(sql);
	assert(pIndices.length == 2);
	
	char[] name = "sean";
	DateTime bday;
	parseDateTime("1987-03-19 15:30:37", bday);
	
	auto execSql = new DisposableStringWriter(5);
	
	virtualBind(sql, pIndices, [BindType.String, BindType.DateTime], [cast(void*)&name, cast(void*)&bday], new SqlGenerator, execSql);
	assert(execSql.get == "select * from user where name = 'sean' and birthday = '1987-03-19 15:30:37'", execSql.get);
	
	execSql.free;
}
}