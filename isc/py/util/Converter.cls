/// Convert InterSystems IRIS datatypes to python datatypes
Class isc.py.util.Converter
{

/// Escapes string to be used as an argument in Python functions, etc.
/// Should always eval as a string
/// If usePython = 1 then Python is used to escape the string.
/// If usePython = 0 then $zcvt is used.
/// Please report if you found a faulty string, which $zcvt does not escape correctly.
/// Python escape uses PyUnicode_FromString -> PyUnicode_DecodeUTF8Stateful
/// Source: https://github.com/python/cpython/blob/master/Objects/unicodeobject.c#L4813
ClassMethod EscapeString(string As %String, usePython As %Boolean = {$$$NO}) As %String
{
	if usePython {
		set result = ##class(isc.py.Callout).EscapeString(string)
	} else {
		set result = "'" _ $zcvt(string, "O", "JS") _ "'"
	}
	
	quit result
}

/// datetime - alias of datetime module
/// date in $horolog
/// w ##class(isc.py.util.Converter).HorologDateToPython(,$h)
ClassMethod HorologDateToPython(datetime As %String = "datetime", date As %Date) As %String [ CodeMode = expression ]
{
..ODBCDateToPython(datetime, $zd(date, 3))
}

/// datetime - alias of datetime module
/// date in ODBC format: YYYY-MM-DD
/// w ##class(isc.py.util.Converter).ODBCDateToPython(,"2019-01-01")
ClassMethod ODBCDateToPython(datetime As %String = "datetime", date As %String) As %String [ CodeMode = expression ]
{
datetime _ ".date(" _ $e(date, 1, 4) _ "," _ +$e(date, 6, 7) _ "," _ + $e(date, 9, 10) _ ")"
}

/// datetime - alias of datetime module
/// time in $horolog format
/// w ##class(isc.py.util.Converter).HorologTimeToPython(,$p($h,",",*))
ClassMethod HorologTimeToPython(datetime As %String = "datetime", time As %String) As %String [ CodeMode = expression ]
{
..ODBCTimeToPython(datetime, $zt(time, 1))
}

/// datetime - alias of datetime module
/// time in ODBC format: hh:mm:ss
/// w ##class(isc.py.util.Converter).ODBCTimeToPython(,"11:12:13")
ClassMethod ODBCTimeToPython(datetime As %String = "datetime", time As %String) As %String [ CodeMode = expression ]
{
datetime _ ".time(" _ +$e(time,1,2) _ "," _ +$e(time,4,5) _ "," _ + $e(time,7,8) _ ")"
}

/// Convert boolean to Python
/// w ##class(isc.py.util.Converter).BooleanToPython(1)
ClassMethod BooleanToPython(boolean As %Boolean) As %String [ CodeMode = expression ]
{
$case(boolean, $$$YES:"True", $$$NO:"False", :"'" _ boolean _ "'")
}

/// Convert Python boolean to boolean
/// w ##class(isc.py.util.Converter).PythonToBoolean("True")
ClassMethod PythonToBoolean(boolean As %String) As %Boolean [ CodeMode = expression ]
{
$case(boolean, "True":$$$YES, "False":$$$NO, :"")
}

/// Convert Horolog Timestamp to Python Timestamp
/// datetime - alias of datetime module
/// timestamp - timesptamp in ODBC format: YYYY-MM-DD hh:ss:mm
/// w ##class(isc.py.util.Converter).HorologTimeStampToPython(, $h)
ClassMethod HorologTimeStampToPython(datetime As %String = "datetime", timestamp As %String) [ CodeMode = expression ]
{
..UnixtimeToPython(datetime, $zdt(timestamp,-2))
}

/// Convert ODBC Timestamp to Python Timestamp
/// datetime - alias of datetime module
/// timestamp - timesptamp in ODBC format: YYYY-MM-DD hh:ss:mm
/// w ##class(isc.py.util.Converter).ODBCTimeStampToPython(, "2011-01-01 01:01:01")
ClassMethod ODBCTimeStampToPython(datetime As %String = "datetime", timestamp As %TimeStamp) [ CodeMode = expression ]
{
..UnixtimeToPython(datetime, $zdt($zdth(timestamp,3,1),-2))
}

/// Convert unixtime to Python timestamp
/// datetime - alias of datetime module
/// unixtime - time in unixtime
/// w ##class(isc.py.util.Converter).UnixtimeToPython(, $zdt($h,-2))
ClassMethod UnixtimeToPython(datetime As %String = "datetime", unixtime As %Integer) As %String [ CodeMode = expression ]
{
datetime _ ".datetime.fromtimestamp(" _ unixtime _ ")"
}

/// Convert collection to %List
/// If saveKeys=0 returns: $lb(val1, val2, ..., valN)
/// If saveKeys=1 returns: $lb("key1=val1", "key2=val2", ..., "keyN=valN")
/// zw ##class(isc.py.util.Converter).CollectionToList()
ClassMethod CollectionToList(collection As %Collection.AbstractIterator, saveKeys As %Boolean = {$$$NO}) As %List [ Internal ]
{
	set list = ""
	set key = ""
	while collection.GetNext(.key) {
		quit:key=""
		set value = collection.GetAt(key)
		if saveKeys {
			set list = list _ $lb(key _ "=" _ value)
		} else {
			set list = list _ $lb(value) 
		}
	}
	
	quit list
}

/// Convert dynamic object or array to %List
/// If saveKeys=0 returns: $lb(val1, val2, ..., valN)
/// If saveKeys=1 returns: $lb("key1=val1", "key2=val2", ..., "keyN=valN")
/// zw ##class(isc.py.util.Converter).DynamicToList([1,2,3])
ClassMethod DynamicToList(obj As %DynamicObject, saveKeys As %Boolean = {$$$NO}) As %List [ Internal ]
{
	set list = ""
	set iterator = obj.%GetIterator()
	while iterator.%GetNext(.key, .value) {
		// key and value now contain the key for the element and value contains the value.
		if saveKeys {
			set list = list _ $lb(key _ "=" _ value) 
		} else {
			set list = list _ $lb(value) 
		}
	}
	quit list
}

}

