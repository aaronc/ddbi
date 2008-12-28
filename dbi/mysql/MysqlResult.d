module dbi.mysql.MysqlResult;

private import dbi.mysql.c.mysql;

class MysqlResult : IResult
{
private:
    ColumnInfo[] _metadata;
    MysqlDatabase _dbase;
    MYSQL_RES* _result = null;
    MYSQL_ROW _curRow = null;
	uint* _curLengths = null;
	ulong _curFieldCount = 0;


public:
	
	this(MysqlDatabase dbase)
    in{
        assert (dbase !is null);
    }
    body {
       _dbase = dbase; 
    }

    this(MysqlDatabase dbase, MYSQL_RES* res)
    in {
        assert (res !is null);
    }
    body {
        this (dbase);
        result = res;
    }
    
    ColumnInfo[] metadata()
    {
        auto fields = mysql_fetch_fields(result);

        _metadata = new ColumnInfo[fieldCount];
        for (ulong i = 0; i < fieldCount; i++) {
            fromMysqlField(_metadata[i], fields[i]);
        }

        return _metadata;
    }

    ColumnInfo metadata(size_t idx)
    in {
        if (_metadata !is null)
            assert (idx > 0 && idx < _metadata.length);
    }
    body {
        if (_metadata is null)
            metadata();
        return _metadata[idx];
    }

    ulong rowCount() { return mysql_num_rows(result); }
    ulong fieldCount() { return mysql_num_fields(result); }
    ulong affectedRows() { return mysql_affected_rows(_dbase.connection); }

    void close()
    {
        if (result is null)
            throw new DBIException ("This result set was already closed.");

        mysql_free_result(result);
        while (mysql_more_results(_dbase.connection)) {
            auto res = mysql_next_result(_dbase.connection);
            assert(res <= 0);
            result = mysql_store_result(_dbase.connection);
            mysql_free_result(result);
        }
        result = null;
    }

    bool more()
    in {
        assert (result !is null);
    }
    body {
        if (result is null)
            throw new DBIException ("This result set was already closed.");

        return cast(bool)mysql_more_results(_dbase.connection);
    }
    

    MysqlResult next()
    {
        if (result !is null) {
        	mysql_free_result(result);
        }
        
        auto res = mysql_next_result(_dbase.connection);
        if (res == 0) {
            result = mysql_store_result(_dbase.connection);
            return this;
        }
        else if(res < 0) return null;
        else {
            throw new DBIException("Failed to retrieve next result set.");
        }
    }

    bool valid() { return result !is null; }
    
    bool nextRow()
    {
    	
    }
	
	bool getField(inout bool, size_t idx);
	bool getField(inout ubyte, size_t idx);
	bool getField(inout byte, size_t idx);
	bool getField(inout ushort, size_t idx);
	bool getField(inout short, size_t idx);
	bool getField(inout uint, size_t idx);
	bool getField(inout int, size_t idx);
	bool getField(inout ulong, size_t idx);
	bool getField(inout long, size_t idx);
	bool getField(inout float, size_t idx);
	bool getField(inout double, size_t idx);
	bool getField(inout char[], size_t idx);
	bool getField(inout ubyte[], size_t idx);
	bool getField(inout Time, size_t idx);
	bool getField(inout DateTime, size_t idx);
}

package:

DbiType fromMysqlType(enum_field_types type)
{
    with (enum_field_types) {
        switch (type) {
            case MYSQL_TYPE_DECIMAL:
                return DbiType.Decimal;
            case MYSQL_TYPE_TINY:
                return DbiType.Byte;
            case MYSQL_TYPE_SHORT:
                return DbiType.Short;
            case MYSQL_TYPE_LONG:
            case MYSQL_TYPE_ENUM:
                return DbiType.Int;
            case MYSQL_TYPE_FLOAT:
                return DbiType.Float;
            case MYSQL_TYPE_DOUBLE:
                return DbiType.Double;
            case MYSQL_TYPE_NULL:
                return DbiType.Null;
            case MYSQL_TYPE_TIMESTAMP:
                 return DbiType.DateTime;
            case MYSQL_TYPE_LONGLONG:
                return DbiType.Long;
            case MYSQL_TYPE_INT24:
                 return DbiType.Int;
            case MYSQL_TYPE_DATE:
            case MYSQL_TYPE_TIME:
            case MYSQL_TYPE_DATETIME:
            case MYSQL_TYPE_YEAR:
            case MYSQL_TYPE_NEWDATE:
                return DbiType.DateTime;
            case MYSQL_TYPE_BIT:
                assert(false);
            case MYSQL_TYPE_NEWDECIMAL:
                return DbiType.Decimal;
            case MYSQL_TYPE_SET:
                assert(false);
            case MYSQL_TYPE_TINY_BLOB:
            case MYSQL_TYPE_MEDIUM_BLOB:
            case MYSQL_TYPE_LONG_BLOB:
            case MYSQL_TYPE_BLOB:
                return DbiType.Binary;
            case MYSQL_TYPE_VARCHAR:
            case MYSQL_TYPE_VAR_STRING:
            case MYSQL_TYPE_STRING:
                return DbiType.String;
            case MYSQL_TYPE_GEOMETRY:
                assert(false);
            default:
                return DbiType.None;
        }
    }
}

void fromMysqlField(inout ColumnInfo column, MYSQL_FIELD field)
{
    column.name = field.name[0..field.name_length];
    column.name.length = field.name_length;
    column.type = fromMysqlType(field.type);
    column.flags = field.flags;
}