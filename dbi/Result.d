module dbi.Result;

public import dbi.Metadata;
public import dbi.util.Memory;

public import tango.time.Time;

abstract class Result
{
	Allocator allocator()
	{
		return alloc_;
	}
    
	void allocator(Allocator alloc)
    {
    	alloc_ = alloc;
    }
    
	protected Allocator alloc_;
    
	abstract bool validResult();
	abstract Result nextResult();
	abstract bool moreResults();
	abstract ulong rowCount();
	abstract ulong fieldCount();
	abstract ulong affectedRows();

	abstract FieldInfo[] rowMetadata();
	
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
	
	bool fetchRow(BindTypes...)(ref BindTypes bind)
    {
		if(!nextRow) return false;
		
		uint idx = 0;
		foreach(Index, Type; BindTypes)
		{
			static if(is(Type : BindInfo))
	    	{
				auto bindInfo = cast(BindInfo)bind[Index];
				
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