module dbi.Metadata;

public import dbi.ColumnInfo;

interface IMetadataProvider
{
	bool hasTable(char[] tablename);
	ColumnInfo[] getTableInfo(char[] tablename);
}

debug(DBITest) {
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
			auto ti = db.getTableInfo("dbi_test"); 
			assert(ti);
			assert(ti.length == 6);
			
			ColumnInfo[char[]] fNames;
			foreach(col; ti)
				fNames[col.name] = col;
			
			auto pID = "id" in fNames;
			assert(pID);
			assert(pID.primaryKey);
			assert("name" in fNames);
			assert("binary" in fNames);
			assert("dateofbirth" in fNames);
			assert("i" in fNames);
			assert("f" in fNames);
		}
	}
}
