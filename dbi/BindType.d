module dbi.BindType;

//TODO add Date and TimeOfDay binding
enum BindType : ubyte { Null, Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, String, Binary, Time, DateTime };

struct BindInfo
{
	BindType[] types;
	void*[] ptrs;	
}

interface INullableBinder
{
	BindInfo bindInfo();
	void setNull(size_t idx);
}