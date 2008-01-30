module dbi.PreparedStatement;

public import tango.group.time;

enum BindType : ubyte { Null, Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, String, Binary, Time, DateTime };

interface IPreparedStatementProvider
{
	IPreparedStatement prepare(char[] sql);
	void beginTransact();
	void rollback();
	void commit();
}

interface IPreparedStatement
{
	uint getParamCount();
	FieldInfo[] getResultMetadata();
	void setParamTypes(BindType[] paramTypes);
	void setResultTypes(BindType[] resTypes);
	bool execute();
	bool execute(void*[] bind);
	bool fetch(void*[] bind);
	void prefetchAll();
	void reset();
	ulong getLastInsertID();
	char[] getLastErrorMsg();
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
