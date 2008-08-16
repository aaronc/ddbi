﻿/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.Statement;

public import tango.group.time;

public import dbi.ColumnInfo;

interface IStatement
{
	uint getParamCount();
	ColumnInfo[] getResultMetadata();
	void setParamTypes(BindType[] paramTypes);
	void setResultTypes(BindType[] resTypes);
	void execute();
	void execute(void*[] bind);
	bool fetch(void*[] bind, void* delegate(size_t) allocator = null);
	void prefetchAll();
	ulong getLastInsertID();
	void reset();
	void close();
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