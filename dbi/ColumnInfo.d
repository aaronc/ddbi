module dbi.ColumnInfo;

public import dbi.BindType;

struct ColumnInfo
{
	char[] name;
	BindType type;
	bool notNull;
	bool autoIncrement;
	bool primaryKey;
	ulong limit;
}