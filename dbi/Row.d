module dbi.Row;

/**
  Class: Row

  Provide access to a single row in a result set.
 */
class Row {
  /**
    Function: opIndex
    
    Get a fields contents by index

    Parameters:
    int - field index

    Example:
    (begin code)
    Row row = res.fetchRow();
    printf("first=%.*s, last=%.*s\n", row[0], row[1]);
    (end code)
   */
  char[] opIndex(int idx) {
    return get(idx);
  }

  /**
    Function: opIndex
    
    Get a fields contents by field name.

    Parameters:
    char[] - field name

    Example:
    (begin code)
    Row row = res.fetchRow();
    printf("first=%.*s, last=%.*s\n", row["first"], row["last"]);
    (end code)
  */
  char[] opIndex(char[] name) {
    return get(name);
  }

  /**
    Function: get
    
    Get a fields contents by index

    Parameters:
    int - field index
   */
  char[] get(int idx) {
    return fieldValues[idx];
  }

  /**
    Function: get
    
    Get a fields contents by field name

    Parameters:
    char[] - field name
   */
  char[] get(char[] name) {
    return fieldValues[getFieldIndex(name)];
  }

  /**
    Function: getFieldIndex
    
    Get the field index by field name
   */
  int getFieldIndex(char[] name) {
    for (int idx=0; idx < fieldNames.length; idx++) {
      if (fieldNames[idx] == name) return idx;
    }
    
    return -1; /// @todo throw an error
  }

  /**
    Function: getFieldType
    
    Get the field type

    Parameters:
    int - field index
   */
  int getFieldType(int idx) {
    return fieldTypes[idx];
  }

  /**
    Function: getFieldDecl
    
    Get a field's SQL declaration

    Parameters:
    int - field index
   */
  char[] getFieldDecl(int idx) {
    return fieldDecls[idx];
  }

  /**
    Function: addField
    
    Add a new field to this row

    Parameters:
    char[] - name
    char[] - value
    char[] - SQL declaration, i.e. varchar(20), decimal(12,2), etc...
    int - SQL type

    Todo:
    
    SQL type should be defined by the D DBI DBD interface spec, therefore
    each DBD module will act exactly alike.
   */
  void addField(char[] name, char[] value, char[] decl, int type) {
    fieldNames  ~= name.dup;
    fieldValues ~= value.dup;
    fieldDecls  ~= decl.dup;
    fieldTypes  ~= type;
  }

  private {
    char[][] fieldNames;
    char[][] fieldValues;
    char[][] fieldDecls;
    int[]    fieldTypes;
  }
  
  unittest {
    void s1(char[] s) { printf("%.*s\n", s); }
    void s2(char[] s) { printf("   ...%.*s\n", s); }
    
    s1("dbi.Row:");
    Row r1 = new Row();
    r1.addField("name", "John Doe", "text",    3);
    r1.addField("age",  "23",       "integer", 1);

    s2("get(int)");
    assert(r1.get(0) == "John Doe");

    s2("get(char[])");
    assert(r1.get("name") == "John Doe");

    s2("[int]");
    assert(r1[0] == "John Doe");

    s2("[char[]]");
    assert(r1["age"] == "23");

    s2("getFieldIndex");
    assert(r1.getFieldIndex("name") == 0);

    s2("getFieldType");
    assert(r1.getFieldType(0) == 3);
    
    s2("getFieldDecl");
    assert(r1.getFieldDecl(1) == "integer");
  }
}
