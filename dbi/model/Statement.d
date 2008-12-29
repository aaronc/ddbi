/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.model.Statement;

public import tango.group.time;

public import dbi.model.Metadata;

interface IStatementProvider
{
	Statement prepare(char[] sql);
	Statement doPrepare(char[] sql);
	void uncacheStatement(Statement st);
	void uncacheStatement(char[] sql);
}

abstract class Statement
{
	this(char[] sql)
	{
		sql_ = sql;
	}
	
	~this () {
		close();
	}
	
	char[] sql() { return sql_;}
	private char[] sql_;
	
	uint getParamCount();
	FieldInfo[] getResultMetadata();
	
	void setParamTypes(BindType[] paramTypes)
	{
		paramTypes_ = paramTypes;
	}
	private BindType[] paramTypes_;
	
	void resetParamTypes()
	{
		paramTypes_ = null;
	}
	
	void setResultTypes(BindType[] resTypes)
	{
		resTypes_ = resTypes;
	}
	private BindType[] resTypes_;
	
	void resetResultTypes()
	{
		resTypes_ = null;
	}
	
	void doExecute(void*[] bind);
	bool doFetch(void*[] bind, out bool[] isNull, void* delegate(size_t) allocator = null);
	void prefetchAll();
	ulong affectedRows();
	ulong getLastInsertID();
	void reset();
	
	package void setCacheProvider(IStatementProvider cacheProvider)
	{
		cacheProvider_ = cacheProvider;
	}
	private IStatementProvider cacheProvider_;
	
	void close()
	{
		if(cacheProvider_ !is null) {
			//cacheProvider_.uncacheStatement(this);
		}
	}
	
	final void execute(Types...)(ref Types bind)
	{
		static if(Types.length) {
			void*[] ptrs = setPtrs(bind);
			
			if(!paramTypes_.length)
				setParamTypes(setBindTypes(bind));
			
			doExecute(ptrs);
		}
		else doExecute(null);
	}
	
	final bool fetch(Types...)(ref Types bind)
	{
		void*[] ptrs = setPtrs(bind);
		
		if(!resTypes_.length)
			setResultTypes(setBindTypes(bind));
		
		bool[] isNull;
		auto res = doFetch(ptrs, isNull);
		
		uint i = 0;
		foreach(x; bind)
		{
			static if(is(typeof(x) == BindInfo)) {
				x.isNull = isNull[i .. i + x.types.length];
				i += x.types.length;
			}
			else ++i;
		}
		
		return res;
	}
	
	static BindType[] setBindTypes(Types...)(Types bind)
	{
		BindType[] types;			
		
		foreach(x; bind)
		{
			static if(is(typeof(x) == BindInfo))
				types ~= bind[Index].types;
			else types ~= getBindType!(typeof(x))();
		}
		
		return types;
	}
	
	static void*[] setPtrs(Types...)(ref Types bind)
	{
		void*[] ptrs;
		
		foreach(Index, Type; Types)
		{
			static if (is(Type == BindInfo))
				ptrs ~= bind[Index].ptrs;
			else ptrs ~= &bind[Index];
		}
		
		return ptrs;
	}
}

BindType getBindType(T)()
{
	static if(is(T == bool))
	{
		return BindType.Bool;
	}
	else static if(is(T == byte))
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
	else static assert(false, "Unknown bind type " ~ T.stringof);
}