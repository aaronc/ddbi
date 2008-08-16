module testddbi;

import tango.util.log.Log,
       tango.util.log.Config;

import dbi.SqlGen,
	   dbi.Registry, 
       dbi.Database,
       dbi.Statement;

version (dbi_sqlite) {
    //This import is to fire the static constructor that registers Sqlite with the Registry
	private import dbi.sqlite.SqliteDatabase;
    //TODO: how to make this fire in the future, without changing code?  Perhaps just import all supported?
}

version (dbi_mysql) {
    //This import is to fire the static constructor that registers Sqlite with the Registry
	private import dbi.mysql.MysqlDatabase;
}

import dbi.VirtualStatement;

void main(char[][] args) {
	auto logger = Log.getLogger(args[0]);
	logger.info("testing ddbi");

	if (args.length > 1) {
		auto db = getDatabaseForURL(args[1]);
		db.test;
		
	} else {
		logger.error("usage: testddbi DBURL");
	}
	
	logger.info("testing complete");
}

