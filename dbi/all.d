/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.all;

version (build) {
	pragma (ignore);
}

version (dbi_sqlite) {
	import dbi.sqlite.SqliteDatabase;
}

version(dbi_mysql) {
	import dbi.mysql.MysqlDatabase;
}

public import dbi.Database,
		dbi.DBIException,
		dbi.ErrorCode,
		dbi.Registry;

