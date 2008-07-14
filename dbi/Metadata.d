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

debug(UnitTest) {
	class MetadataTest
	{
		this(IMetadataProvider db)
		{
			this.db = db;
		}
		
		void run()
		{
			test1;
		}
		
		
		IMetadataProvider db;
		
		void test1()
		{
			assert(db.hasTable("test"));
			TableInfo ti;
			assert(db.getTableInfo("test", ti));
			assert(ti.fieldNames.length == 4);
			assert(ti.primaryKeyFields.length == 1);
			
			char[][char[]] fNames;
			foreach(f; ti.fieldNames)
				fNames[f] = f;
			
			assert("id" in fNames);
			assert("name" in fNames);
			assert("binary" in fNames);
			assert("dateofbirth" in fNames);
			
			assert(ti.primaryKeyFields[0] == "id");
		}
	}
}
