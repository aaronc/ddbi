module dbi.Result;

public import dbi.Row;
public import dbi.Statement;

Result query(IStatement st, ...)
{
	if(!_arguments.length) {
		 st.execute;
		 return Result(st);
	}
	
	void*[] ptrs;
	BindType[] types;
	
	bindArgs(_argptr, _arguments, ptrs, types);
	
	st.setParamTypes(types);
	st.execute(ptrs);
	return Result(st);
}

class Result
{
	this(IStatement st)
	{
		this.st = st;
		this.metadata_ = st.getResultMetadata;
		
		auto len = metadata_.length;
		if(!len) return;
		
		auto resTypes = new BindType[len];
		for(uint i = 0; i < len; ++i) resTypes[i] = BindType.String;
		st.setResultTypes(resTypes);
	}
	private IStatement st;
	public FieldInfo[] metadata() {return metadata_;}
	private FieldInfo[] metadata_;
	
	static Result opCall(IStatement st)
	{
		return new Result(st);
	}
	
	Row fetch()
	{
		auto len = metadata_.length;
		if(!len) return null;
		
		auto row = new Row(metadata_);
		void*[] ptrs = new void*[len];
		row.values = new char[][len];
		
		for(uint i = 0; i < len; ++i)
		{
			ptrs[i] = &row.values[i];
		}
		
		if(!st.fetch(ptrs)) return null;
		return row;
	}
	
	void reset()
	{
		st.reset;
	}
	
	void finalize()
	{
		st.close;
	}
}

void bindArgs(void* argptr, TypeInfo[] arguments,
              out void*[] ptrs, out BindType[] types)
{
	auto len = arguments.length;
	
	ptrs.length = len;
	types.length = len;
	
	for(uint i = 0; i < len; ++i)
	{
		if(arguments[i] == typeid(byte))
		{
		    ptrs[i] = argptr;
		    types[i] = BindType.Byte;
		    argptr += byte.sizeof;
		}
		else if(arguments[i] == typeid(ubyte))
		{
		    ptrs[i] = argptr;
		    types[i] = BindType.UByte;
		    argptr += ubyte.sizeof;
		}
		else if(arguments[i] == typeid(short))
		{
		    ptrs[i] = argptr;
		    types[i] = BindType.Short;
		    argptr += short.sizeof;
		}
		else if(arguments[i] == typeid(ushort))
		{
		    ptrs[i] = argptr;
		    types[i] = BindType.UShort;
		    argptr += ushort.sizeof;
		}
		else if(arguments[i] == typeid(int))
		{
		    ptrs[i] = argptr;
		    types[i] = BindType.Int;
		    argptr += int.sizeof;
		}
		else if(arguments[i] == typeid(uint))
		{
		    ptrs[i] = argptr;
		    types[i] = BindType.UInt;
		    argptr += uint.sizeof;
		}
		else if(arguments[i] == typeid(long))
		{
			ptrs[i] = argptr;
		    types[i] = BindType.Long;
		    argptr += long.sizeof;
		}
		else if(arguments[i] == typeid(ulong))
		{
			ptrs[i] = argptr;
		    types[i] = BindType.ULong;
		    argptr += ulong.sizeof;
		}
		else if (arguments[i] == typeid(float))
		{
			ptrs[i] = argptr;
		    types[i] = BindType.Float;
		    argptr += float.sizeof;
		}
		else if (arguments[i] == typeid(double))
		{
			ptrs[i] = argptr;
		    types[i] = BindType.Double;
		    argptr += double.sizeof;
		}
		else if (arguments[i] == typeid(char[]))
		{
			ptrs[i] = argptr;
		    types[i] = BindType.String;
		    argptr += ptrs.sizeof;
		}
		else if (arguments[i] == typeid(ubyte[]) || arguments[i] == typeid(void[]))
		{
			ptrs[i] = argptr;
		    types[i] = BindType.Binary;
		    argptr += ptrs.sizeof;
		}
		else if (arguments[i] == typeid(Time))
		{
			ptrs[i] = argptr;
		    types[i] = BindType.Time;
		    argptr += Time.sizeof;
		}
		else if (arguments[i] == typeid(DateTime))
		{
			ptrs[i] = argptr;
		    types[i] = BindType.DateTime;
		    argptr += DateTime.sizeof;
		}
		else assert(false);
	}
}
