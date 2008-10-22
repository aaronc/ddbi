/**
 * Authors: The D DBI project
 * Copyright: BSD license
 */
module dbi.mysql.all;

version (build) {
	pragma (ignore);
}

version (dbi_mysql) {

public import	dbi.mysql.MysqlDatabase,
		dbi.mysql.MysqlResult,
		dbi.all;

}