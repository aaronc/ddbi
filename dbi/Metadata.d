module dbi.Metadata;

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

struct FieldInfo
{
	char[] name;
	BindType type;
}