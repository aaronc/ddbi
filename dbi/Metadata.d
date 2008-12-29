module dbi.Metadata;

public import dbi.BindType;

/+
enum ColumnFlag : ulong
{
    NotNull = 1,
    PrimaryKey = 2,
    UniqueKey = 4,
    MultipleKey = 8,
    Blob = 16,
    Unsigned = 32,
    ZeroFill = 64,
    Binary = 128
}

struct ColumnInfo
{
    BindType type;
    char[] name;
    ulong flags;

    bool notNull() { return cast(bool)(flags & ColumnFlag.NotNull); }
    bool primaryKey() { return cast(bool)(flags & ColumnFlag.PrimaryKey); }
    bool uniqueKey() { return cast(bool)(flags & ColumnFlag.UniqueKey); }
    bool multipleKey() { return cast(bool)(flags & ColumnFlag.MultipleKey); }
    bool blob() { return cast(bool)(flags & ColumnFlag.Blob); }
    bool unsigned() { return cast(bool)(flags & ColumnFlag.Unsigned); }
    bool binary() { return cast(bool)(flags & ColumnFlag.Binary); }
    bool zeroFill() { return cast(bool)(flags & ColumnFlag.ZeroFill); }
}+/

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