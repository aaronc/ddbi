/**
 * Copyright: LGPL
 */
module dbi.mysql.all;

import	dbi.mysql.MysqlDatabase,
	dbi.mysql.MysqlResult,
	dbi.all;

/**
 * Note:
 *	Written against MySQL 5.1 docs (revision 1760)
 */
package ErrorCode specificToGeneral (uint error) {
	if (error > 999  && error < 2000) {
		return ErrorCode.ServerError;
	}
	switch (error) {
		case (0):
			return ErrorCode.NoError;
		case (2000):
			return ErrorCode.Unknown;
		case (2001):
			return ErrorCode.SocketError;
		case (2002):
			return ErrorCode.ConnectionError;
		case (2003):
			return ErrorCode.ConnectionError;
		case (2004):
			return ErrorCode.SocketError;
		case (2005):
			return ErrorCode.ConnectionError;
		case (2006):
			return ErrorCode.ConnectionError;
		case (2007):
			return ErrorCode.VersionError;
		case (2008):
			return ErrorCode.Unknown;
		case (2009):
			return ErrorCode.ConnectionError;
		case (2010):
			return ErrorCode.SocketError;
		case (2011):
			return ErrorCode.SocketError;
		case (2012):
			return ErrorCode.ConnectionError;
		case (2013):
			return ErrorCode.ConnectionError;
		case (2014):
			return ErrorCode.OutOfSync;
		case (2015):
			return ErrorCode.SocketError;
		case (2016):
			return ErrorCode.SocketError;
		case (2017):
			return ErrorCode.SocketError;
		case (2018):
			return ErrorCode.SocketError;
		case (2019):
			return ErrorCode.Unknown;
		case (2020):
			return ErrorCode.ConnectionError;
		case (2021):
			return ErrorCode.ConnectionError;
		case (2022):
			return ErrorCode.SocketError;
		case (2023):
			return ErrorCode.SocketError;
		case (2024):
			return ErrorCode.SocketError;
		case (2025):
			return ErrorCode.SocketError;
		case (2026):
			return ErrorCode.SocketError;
		case (2027):
			return ErrorCode.SocketError;
		case (2028):
			return ErrorCode.LicenseError;
		case (2029):
			return ErrorCode.InvalidData;
		case (2030):
			return ErrorCode.NotPrepared;
		case (2031):
			return ErrorCode.ParamsNotBound;
		case (2032):
			return ErrorCode.InvalidData;
		case (2033):
			return ErrorCode.InvalidParams;
		case (2034):
			return ErrorCode.InvalidParams;
		case (2035):
			return ErrorCode.InvalidData;
		case (2036):
			return ErrorCode.InvalidParams;
		case (2037):
			return ErrorCode.ConnectionError;
		case (2038):
			return ErrorCode.ConnectionError;
		case (2039):
			return ErrorCode.ConnectionError;
		case (2040):
			return ErrorCode.ConnectionError;
		case (2041):
			return ErrorCode.ConnectionError;
		case (2042):
			return ErrorCode.ConnectionError;
		case (2043):
			return ErrorCode.ConnectionError;
		case (2044):
			return ErrorCode.ConnectionError;
		case (2045):
			return ErrorCode.ConnectionError;
		case (2046):
			return ErrorCode.ConnectionError;
		case (2047):
			return ErrorCode.ConnectionError;
		case (2048):
			return ErrorCode.ConnectionError;
		case (2049):
			return ErrorCode.VersionError;
		case (2050):
			return ErrorCode.InvalidQuery;
		case (2051):
			return ErrorCode.NoData;
		case (2052):
			return ErrorCode.NoData;
		case (2053):
			return ErrorCode.NoData;
		case (2054):
			return ErrorCode.NotImplemented;
		default:
	}
	return ErrorCode.Unknown;
}