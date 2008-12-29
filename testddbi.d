module testddbi;

import tango.util.log.Log,
       tango.util.log.Config;

import dbi.DBI;

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

