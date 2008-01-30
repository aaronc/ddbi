module dbi.Metadata;

interface IMetadataProvider
{
	bool hasTable(char[] tablename);
	bool getTableInfo(char[] tablename, inout TableInfo info);
}

struct TableInfo
{
	char[][] fieldNames;
	char[][] primaryKeyFields;
}
