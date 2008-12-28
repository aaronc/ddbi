module dbi.Result;

public import dbi.Row;
public import dbi.Statement;
public import dbi.Metadata;

abstract class IResult
{
	abstract ulong rowCount();
	abstract ulong fieldCount();
	abstract ulong affectedRows();

    //void close();
	abstract bool validResult();
    
	abstract ColumnInfo2[] rowMetadata();

	abstract IResult nextResult();
	abstract bool moreResults();
	
	abstract bool nextRow();
	
	abstract bool getField(inout bool, size_t idx);
	abstract bool getField(inout ubyte, size_t idx);
	abstract bool getField(inout byte, size_t idx);
	abstract bool getField(inout ushort, size_t idx);
	abstract bool getField(inout short, size_t idx);
	abstract bool getField(inout uint, size_t idx);
	abstract bool getField(inout int, size_t idx);
	abstract bool getField(inout ulong, size_t idx);
	abstract bool getField(inout long, size_t idx);
	abstract bool getField(inout float, size_t idx);
	abstract bool getField(inout double, size_t idx);
	abstract bool getField(inout char[], size_t idx);
	abstract bool getField(inout ubyte[], size_t idx);
	abstract bool getField(inout Time, size_t idx);
	abstract bool getField(inout DateTime, size_t idx);
	
	bool fetchRow(BindTypes...)(ref BindType bind)
    {
		if(!nextRow) return false;
		
		uint idx = 0;
		foreach(Index, Type; BindTypes)
		{
			static if(is(Type : BindInfo) || is(Type : INullableBinder))
	    	{
				static if(is(Type : INullableBinder)) {
					auto binder = cast(INullableBinder)bind[Index];
					assert(binder !is null);
					auto bindInfo = binder.bindInfo;
				}
				else auto bindInfo = cast(Binder)bind[Index];
				
				auto ptrs = bindInfo.ptrs;
				bool res;
	    		foreach(i, type; bindInfo.types)
	    		{
	    			switch(type)
	    			{
	    			case BindType.Bool:
	    				bool* ptr = cast(bool*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.Byte:
	    				byte* ptr = cast(byte*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.Short:
	    				short* ptr = cast(short*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.Int:
	    				int* ptr = cast(int*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.Long:
	    				long* ptr = cast(long*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.UByte:
	    				ubyte* ptr = cast(ubyte*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.UShort:
	    				ushort* ptr = cast(ushort*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.UInt:
	    				uint* ptr = cast(uint*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.ULong:
	    				ulong* ptr = cast(ulong*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.Float:
	    				float* ptr = cast(float*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.Double:
	    				double* ptr = cast(double*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.String:
	    				char[]* ptr = cast(char[]*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.Binary:
	    				ubyte[]* ptr = cast(ubyte[]*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.Time:
	    				Time* ptr = cast(T.Time*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.DateTime:
	    				DateTime* ptr = cast(T.DateTime*)ptrs[i];
	    				res = getField(*ptr, idx);
	    				break;
	    			case BindType.Null:
	    			}
	    			static if(is(Type : INullableBinder))
	    				if(!res) binder.setNull(i);
	    			++idx;
	    		}
	    	}
	    	else {
	    		getField(bind[Index], idx);
	    		++idx;
	    	}
		}
    	
		return true;
    }
}

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
