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
			assert(db.hasTable("dbi_test"));
			TableInfo ti;
			assert(db.getTableInfo("dbi_test", ti));
			assert(ti.fieldNames.length == 6);
			assert(ti.primaryKeyFields.length == 1);
			
			char[][char[]] fNames;
			foreach(f; ti.fieldNames)
				fNames[f] = f;
			
			assert("id" in fNames);
			assert("name" in fNames);
			assert("binary" in fNames);
			assert("dateofbirth" in fNames);
			assert("i" in fNames);
			assert("f" in fNames);
			
			assert(ti.primaryKeyFields[0] == "id");
		}
	}
}
