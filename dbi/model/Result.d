/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.model.Result;

public import dbi.model.Metadata;
public import dbi.util.Memory;

public import tango.time.Time;
import tango.core.Vararg;

debug {
	import tango.util.log.Log;
	Logger log;
	static this() {
		log = Log.lookup("dbi.model.Result");
	}
}

/**
*
*/
abstract class Result
{
	/**
	*	Loads the next row in the result set.
	*
	*	Returns: true if there was next row and it was correctly loaded, false if
	*	there was not another row or there was an error loading it.
	*/
	abstract bool nextRow();
	
	
	/**
	*	Fetchs a row from the current result set binding the returned field
	* 	values to the variadic arguments provided in the call to fetchRow().
	*
	*	Arguments of the following types can be used as bind arguments:
			bool
			byte
			ubyte
			short
			ushort
			int
			uint
			long
			ulong
			float
			double
			char[]
			void[]
			ubyte[]
			tango.time.Time
			tango.time.DateTime
			dbi.model.BindType.BindInfo
	*
	*	Examples:
	*	------------------
	*	uint id;
	*	char name;
	*	
	*	while(res.fetchRow(id,name)) { 
	*		Stdout.formatln("id: {}, name: {}", id, name);
	*	}
	*	------------------ 
	*
	*	Returns: true if a row was successfully loaded and bound to the passed
	*	arguments, false if there are no more rows 
	*/
	bool fetchRow(...)
    {
		if(!nextRow) return false;

		uint idx = 0;
		
		void bindBindInfo(ref BindInfo bindInfo)
		{
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
    				Time* ptr = cast(Time*)ptrs[i];
    				res = getField(*ptr, idx);
    				break;
    			case BindType.DateTime:
    				DateTime* ptr = cast(DateTime*)ptrs[i];
    				res = getField(*ptr, idx);
    				break;
    			case BindType.Null:
    			}
    			++idx;
    		}
		}
		
		for(int i = 0; i < _arguments.length; ++i)
		{
			if(_arguments[i] == typeid(bool*))
				getField(*va_arg!(bool*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(ubyte*))
				getField(*va_arg!(ubyte*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(byte*))
				getField(*va_arg!(byte*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(ushort*))
				getField(*va_arg!(ushort*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(short*))
				getField(*va_arg!(short*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(uint*))
				getField(*va_arg!(uint*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(int*))
				getField(*va_arg!(int*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(ulong*))
				getField(*va_arg!(ulong*)(_argptr),idx);
				
			else if(_arguments[i] == typeid(long*))
				getField(*va_arg!(long*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(float*))
				getField(*va_arg!(float*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(double*))
				getField(*va_arg!(double*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(ubyte[]*))
				getField(*va_arg!(ubyte[]*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(void[]*))
				getField(*va_arg!(ubyte[]*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(char[]*))
				getField(*va_arg!(char[]*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(Time*))
				getField(*va_arg!(Time*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(DateTime*))
				getField(*va_arg!(DateTime*)(_argptr),idx);
			
			else if(_arguments[i] == typeid(BindInfo))
			{
				auto bindInfo = va_arg!(BindInfo)(_argptr);
	    		bindBindInfo(bindInfo);
			}
			else assert(false, "Unknown bind type " ~ _arguments[i].toString);
			++idx;
		}
    	
		return true;
    }

	Allocator allocator()
	{
		return alloc_;
	}
    
	void allocator(Allocator alloc)
    {
    	alloc_ = alloc;
    }
    
	protected Allocator alloc_;
	
	/**
	*	Returns: The number of rows in the current result set
	*/ 
	abstract ulong rowCount();
	
	/**
	*	Returns: The number of fields per row for the current result set.
	*/
	abstract ulong fieldCount();
	
	/**
	*	Returns the number of rows affected by the current sql statement.
	*
	*	For multi-statement sql queries, when nextResult() returns true
	*	a valid result set will be present (in which case validResult()
	* 	will return true) and/or affectedRows() will be valid (for statements
	*	which do not return a result set).
	*
	*	Returns: The number of rows affected by the current sql statement.
	*/
	abstract ulong affectedRows();

	/**
	* Returns: the row metadata for the current result set.
	*/
	abstract FieldInfo[] rowMetadata();
    
    /**
	*	Returns: true if the current result set is valid, false otherwise.
	*	validResult() may return false even if there are still additional result
	*	sets.  For statements which do not return result sets but modify data,
	*	check affectedRows().
	*	
	*/
	abstract bool validResult();
	
	/**
	*	Closes all result sets for the current query.
	*
	*	Any call to nextResult() after calling closeResult() will fail and
	* 	return false.
	*/
	abstract void closeResult();
    
	/**
	*	Returns: true if there are more results, false otherwise.
	*/
	abstract bool moreResults();
	
	/**
	*	Loads the next result set if there is one.
	*
	*	Returns: true if there was another result and it was loaded properly,
	* 	false otherwise.
	*/
	abstract bool nextResult();
	
	
    ///
	abstract bool getField(inout bool, size_t idx);
	///
	abstract bool getField(inout ubyte, size_t idx);
	///
	abstract bool getField(inout byte, size_t idx);
	///
	abstract bool getField(inout ushort, size_t idx);
	///
	abstract bool getField(inout short, size_t idx);
	///
	abstract bool getField(inout uint, size_t idx);
	///
	abstract bool getField(inout int, size_t idx);
	///
	abstract bool getField(inout ulong, size_t idx);
	///
	abstract bool getField(inout long, size_t idx);
	///
	abstract bool getField(inout float, size_t idx);
	///
	abstract bool getField(inout double, size_t idx);
	///
	abstract bool getField(inout char[], size_t idx);
	///
	abstract bool getField(inout ubyte[], size_t idx);
	///
	abstract bool getField(inout Time, size_t idx);
	///
	abstract bool getField(inout DateTime, size_t idx);
}