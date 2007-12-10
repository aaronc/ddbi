module dbi.PreparedStatement;

version (Phobos) {
	static assert(false, "Phobos version of prepared statements not implemented yet");
} else {
	public import tango.util.time.DateTime;
}

enum BindType { Null, Bool, Byte, Short, Int, Long, UByte, UShort, UInt, ULong, Float, Double, String, Binary, Time };

interface IPreparedStatementProvider
{
	IPreparedStatement prepare(string sql);
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
