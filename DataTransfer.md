# Data Transfer

Transfer data into and from Python. All the methods are defined in `isc.py.Main`. All methods return `%Status`.

# Python -> InterSystems IRIS

- `GetVariable(variable, serialization, .stream, useString)` - get `serialization` of `variable` in `stream`. If `useString` is 1 and variable serialization can fit into string then string is returned instead of the stream.
- `GetVariableJson(variable, .stream, useString)` - get JSON serialization of variable.
- `GetVariablePickle(variable, .stream, useString, useDill)` - get Pickle (or Dill) serialization of variable.

# InterSystems IRIS -> Python

Load data from InterSystems IRIS to Python. 
All these methods support data transfer from any local namespace. `isc.py` package must be available in `namespace`.

## ExecuteQuery

`ExecuteQuery(query, variable, type, namespace)` - transfer results from any valid SQL query into Python. It is the slowest method of data transfer. Use it if `ExecuteGlobal` and its wrappers are unavailable.

Arguments:
- `query` - sql query
- `variable` - target variable on a Python side
- `type` - `list` or Pandas `dataframe`


## ExecuteGlobal

`ExecuteGlobal(global, variable, type, start, end, mask, labels, namespace)` - transfer global data to Python.

Arguments:
- `global` - global name without `^`
- `variable` - target variable on a Python side
- `type` - `list` or Pandas `dataframe`
- `start` - initial global key. Must be integer.
- `end` - final global key. Must be integer.
- `mask` - string, mask for global values. Mask may be shorter than the number of global value fields (in this case fields at the end would be skipped). How to format mask:
  -   `+` use field as is
  -   `-` skip field
  -   `b` - boolean (0 - False, anything else - True)
  -   `d` - date (from $horolog, on Windows only from 1970, on Linux from 1900 see notes for details)
  -   `t` - time ($horolog, seconds since midnight) 
  -   `m` - (moment) timestamp string in YEAR-MONTH-DAY HOUR:MINUTE:SECOND format.
- `labels` - %List of column names, first element is key column name. Therefore: List length must be mask symbol length + 1.

## ExecuteClass

Wrapper for `ExecuteGlobal`. Effectively it parses compiled class definition, constructs `ExecuteGlobal` arguments and calls it. 

`ExecuteClass(class, variable, type, start, end, properties, namespace)` - transfer class data to Python list of tuples or pandas dataframe. `properties` - comma-separated list of properties to form dataframe from. `*` and `?` wildcards are supported. Defaults to * (all properties). %%CLASSNAME property is ignored. Only stored properties can be used.

Arguments:
- `class` - class name
- `variable` - target variable on a Python side
- `type` - `list` or Pandas `dataframe`
- `start` - initial object id. Must be integer.
- `end` - final object id. Must be integer.
- `properties` - comma-separated list of properties to form dataframe from. `*` and `?` wildcards are supported. Defaults to `*` (all properties). `%%CLASSNAME` property is ignored. Only stored properties can be used.

All properties transferred as is except properties of `%Date`, `%Time`, `%Boolean` and `%TimeStamp` types. They are converted to respective Python datatypes.

## ExecuteTable

Wrapper for `ExecuteClass`. Translates table name to class name and calls `ExecuteClass`. Signature:

`ExecuteTable(table, variable, type, start, end, properties, namespace)` - transfer table data to Python list of tuples or pandas dataframe.

Arguments:
- `table` - table name.

Other arguments are passed as is to `ExecuteClass`.

## Notes 

- `ExecuteGlobal`, `ExecuteClass` and `ExecuteTable` generally offer the same speed (as the time to parse class definition is negligible).
- `ExecuteGlobal` is 3-5 times faster than ODBC driver and up to 20 times faster than `ExecuteQuery` on measurable workloads (>0.01 second).
- `ExecuteGlobal`, `ExecuteClass` and `ExecuteTable` only work on the globals with this structure: `^global(key) = $lb(prop1, prop2, ..., propN)` where `key` must be an integer.
- For `ExecuteGlobal`, `ExecuteClass` and `ExecuteTable` supported `%Date` range equals `mktime` range ([windows](https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/mktime-mktime32-mktime64?view=vs-2019): 1970-01-01, [linux](https://linux.die.net/man/3/mktime) 1900-01-01, [mac](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/mktime.3.html)). Use `%TimeStamp` to transfer dates outside of this range.
- For `ExecuteGlobal`, `ExecuteClass` and `ExecuteTable` all arguments besides the source (global, class, table) and variable are optional.

## Examples

Let's say we have [isc.py.test.Person](https://github.com/intersystems-community/PythonGateway/blob/master/isc/py/test/Person.cls) class. Here's how we can use all methods of data transfer:

```
// All the ways to transfer data
set global = "isc.py.test.PersonD"
set class = "isc.py.test.Person"
set table = "isc_py_test.Person"
set query = "SELECT * FROM isc_py_test.Person"

// Common arguments
set variable = "df"
set type = "dataframe"
set start = 1
set end = $g(^isc.py.test.PersonD, start)

// Approach 0: ExecuteGlobal without arguments
set sc = ##class(isc.py.Main).ExecuteGlobal(global, variable _ 0, type)

// Approach 1: ExecuteGlobal with arguments	
// For global transfer labels are not calculated automatically
// globalKey - is global subscript
set labels = $lb("globalKey", "Name", "DOB", "TS", "RandomTime", "AgeYears", "AgeDecimal", "AgeDouble", "Bool")

// mask is 1 element shorter than labels because "globalKey" is global subscript label
// Here we want to skip %%CLASSNAME field
set mask = "-+dmt+++b"

set sc = ##class(isc.py.Main).ExecuteGlobal(global, variable _ 1, type, start, end, mask, labels)

// Approach 2: ExecuteClass
set sc = ##class(isc.py.Main).ExecuteClass(class, variable _ 2, type, start, end)

// Approach 3: ExecuteTable
set sc = ##class(isc.py.Main).ExecuteTable(table, variable _ 3, type, start, end)

// Approach 4: ExecuteTable
set sc = ##class(isc.py.Main).ExecuteQuery(query, variable _ 4, type)
```

You can call this method: `do ##class(isc.py.test.Person).Test()` to check how these data transfer methods work.
