module dbi.util.DateTime;

import tango.time.Time;
import tango.time.chrono.Gregorian;
import ISO8601 = tango.time.ISO8601;
import Integer = tango.text.convert.Integer;

import dbi.Exception;

DateTime toDate(Time t)
{
	DateTime dt;
	Gregorian.generic.split(t, dt.date.year, dt.date.month, 
		dt.date.day, dt.date.doy, dt.date.dow, dt.date.era);
	dt.time = t.time;
	return dt;
}

/*
 * Does a fixed-length unsigned-integer to string conversion.
 * Useful for writing out 2-digit monthes, 4-digit years exactly 
 *
 */
void uitoaFixed(uint len)(uint x, char[] res)
{
	if(res.length < len)
		throw new DBIException("Insufficient buffer size");
	
	const char[] digits = "0123456789";
	for(uint i = 0; i < len; ++i)
	{
		res[len - i - 1] = digits[ x % 10];
		x /= 10;
	}
}

/**
 * Prints a UTC date value in ISO8601 format with a space
 * separating the date and time instead of a 'T'
 * 
 * Params:
 *     dt = the DateTime to print in UTC 
 *     write = a consumer that receives the output
 */
char[] printDateTime(DateTime dt, char[] res)
{
	if(res.length < 19)
		throw new DBIException("Insufficient buffer size");
	
	printDate(dt, res);
	res[10] = ' ';
	printTime(dt, res[11 .. $]);
	
	return res[0 .. 19];
}

/**
 * Prints a UTC date value in ISO8601 format
 * 
 * Params:
 *     dt = the DateTime to print in UTC 
 *     write = a consumer that receives the output
 */
char[] printDate(DateTime dt, char[] res)
{
	if(res.length < 10)
		throw new DBIException("Insufficient buffer size");
	
	uitoaFixed!(4)(dt.date.year, res);
	res[4] = '-';
	uitoaFixed!(2)(dt.date.month, res[5 .. 7]);
	res[7] = '-';
	uitoaFixed!(2)(dt.date.day, res[8 .. 10]);
	
	return res[0 .. 10];
}

/**
 * Prints a UTC time value in ISO8601 format
 * 
 * Params:
 *     dt = the DateTime to print in UTC 
 *     write = a consumer that receives the output
 */
char[] printTime(DateTime dt, char[] res)
{
	if(res.length < 8)
		throw new DBIException("Insufficient buffer size");
	
	uitoaFixed!(2)(dt.time.hours, res);
	res[2] = ':';
	uitoaFixed!(2)(dt.time.minutes, res[3 .. 5]);
	res[5] = ':';
	uitoaFixed!(2)(dt.time.seconds, res[6 .. 8]);
	
	return res[0 .. 8];
	
}

bool parseDateTime(char[] src, ref DateTime dt)
{
	bool tryIso() {
		Time t;
		if(ISO8601.parseDateAndTime(src, t) == 0) return false;
		//dt = Clock.toDate(t);
		dt = toDate(t);
		return true;
	}
	
	if(src.length != 19) {
		dt = DateTime.init;
		return tryIso;
	}
	
	if(!parseDateFixed(src, dt.date)) return tryIso;
	if(!parseTimeFixed(src[11 .. $], dt.time)) return tryIso;
	
	return true;
}

bool parseDateFixed(char[] src, ref Date d)
{
	bool tryIso() {
		Time t;
		if(ISO8601.parseDate(src, t) == 0) return false;
		//auto dt = Clock.toDate(t);
		auto dt = toDate(t);
		d = dt.date;
		return true;
	}
	
	if(src.length != 10) {
		d = Date.init;
		return tryIso;
	}
	
	d.year = Integer.parse(src[0 .. 4]);
	if(src[4] != '-' && src[4] != '/') return tryIso;
	d.month = Integer.parse(src[5 .. 7]);
	if((src[7] != '-' && src[7] != '/') || src[7] != src[4]) return tryIso;
	d.day = Integer.parse(src[8 .. 10]);
	
	return true;
}

bool parseTimeFixed(char[] src, ref TimeOfDay ts)
{
	bool tryIso() {
		/+Time t;
		if(ISO8601.parseTime(src, t) == 0) return false;
		auto dt = Clock.toDate(t);
		ts = dt.time;
		return true;+/
		return false;
	}
	
	if(src.length != 8) {
		ts = TimeOfDay.init;
		return tryIso;
	}
	
	ts.hours = Integer.parse(src[0 .. 2]);
	if(src[2] != ':') return tryIso;
	ts.minutes = Integer.parse(src[3 .. 5]);
	if(src[5] != ':') return tryIso;
	ts.seconds = Integer.parse(src[6 .. 8]);
	
	return true;
}

debug(DBITest) {

	unittest
	{
		Time t;
		DateTime dt;
		
		assert(parseDateFixed("2008-01-15", dt.date)); 
		assert(dt.date.year == 2008, Integer.toString(dt.date.year));
		assert(dt.date.month == 1);
		assert(dt.date.day == 15);
		
		assert(parseDateFixed("1970", dt.date)); 
		assert(dt.date.year == 1970, Integer.toString(dt.date.year));
		assert(dt.date.month == 1);
		assert(dt.date.day == 1);
		
		assert(parseTimeFixed("03:15:47", dt.time));
		assert(dt.time.hours == 3);
		assert(dt.time.minutes == 15);
		assert(dt.time.seconds == 47);
		
		/+assert(parseTimeFixed("2004", dt.time));
		assert(dt.time.hours == 20);
		assert(dt.time.minutes == 4);
		assert(dt.time.seconds == 00);+/
		
		assert(parseDateTime("2008-01-15 03:15:47", dt));;
		assert(dt.date.year == 2008);
		assert(dt.date.month == 1);
		assert(dt.date.day == 15);
		assert(dt.time.hours == 3);
		assert(dt.time.minutes == 15);
		assert(dt.time.seconds == 47);
		
		// January 1st, 2008 00:01:00
		assert(parseDateTime("2007-12-31T23:01-01", dt)); 
		assert(dt.date.year == 2008);
		assert(dt.date.month == 1);
		assert(dt.date.day == 1);
		assert(dt.time.hours == 0);
		assert(dt.time.minutes == 1);
		assert(dt.time.seconds == 0);
		 
		// April 12th, 1985 23:50:30,042
		assert(parseDateTime("1985W155T235030,042", dt));
		assert(dt.date.year == 1985);
		assert(dt.date.month == 4);
		assert(dt.date.day == 12);
		assert(dt.time.hours == 23);
		assert(dt.time.minutes == 50);
		assert(dt.time.seconds == 30);
		assert(dt.time.millis == 42);
		
		 // Invalid time: returns zero
		 assert(!parseDateTime("1902-03-04T10:1a", dt));
		 
		 // Separating T omitted: returns zero
		 assert(!parseDateTime("1902-03-04T10:1a", dt));
		 
		 // Inconsistent separators: all return zero
		 assert(!parseDateTime("200512-01T10:02", dt));
		 assert(!parseDateTime("1985-04-12T10:15:30+0400", dt));
		 assert(!parseDateTime("1902-03-04T050607", dt));

	}
}