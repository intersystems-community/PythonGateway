/// Public entry point to call Python Context
Class isc.py.Main
{

/// This method assumes that variable value is less than $$$MaxStringLength limit
/// Eval code in initialized context and 
/// optionally return variable value.
/// serialization - currenlty: 0 - string serialization, 1 - repr serialization.
/// write ##class(isc.py.Main).SimpleString()
ClassMethod SimpleString(code As %String = "", variable As %String = "", serialization As %Integer = {##class(isc.py.Callout).#SerializationStr}, Output result) As %Status
{
	#dim sc As %Status = $$$OK
	
	try {
		set result = ##class(isc.py.Callout).SimpleString(code, variable, serialization)
	} catch ex {
		set result = ""
		#dim ex As %Exception.General
		if (ex.Name = "<FUNCTION>") {
			set sc = $$$ERROR($$$GeneralError, "Python Error. Probably variable '" _ variable _ "' is longer than current limit: " _ $$$MaxStringLength)
		} else {
			set sc = ex.AsStatus()
		}
	}
	
	set sc = $$$ADDSC(sc, ..GetStatus())
	
	quit sc
}

/// Executes code. If variable is not empty sets variable=code.
/// If variable is undefined
/// code may be a string or a stream
/// write ##class(isc.py.Main).ExcuteCode()
ClassMethod ExcuteCode(code As %Stream.Object, variable As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	quit:$d(code)'=1 $$$ERROR($$$GeneralError, "Code argument should be set to stream or to string") 
	
	if $isObject(code) {
		do code.Rewind()
		set codeLength = code.Size
	} else {
		set codeLength = $l(code)
	}
	
	#dim hasVar As %Boolean = $l($g(variable))>0
	
	// length of code + length of var name + 1 char for '='
	set length = codeLength + $select(hasVar :$l(variable) + 1, 1:0)

	
	if length>$$$MaxStringLength {
		set sc = ##class(isc.py.Callout).StreamInit(length)
		quit:$$$ISERR(sc) sc
		set:hasVar sc = ##class(isc.py.Callout).StreamWrite(variable _ "=")
		quit:$$$ISERR(sc) sc
		
		if $isObject(code) { 
			while 'code.AtEnd {
				set codePiece = code.Read($$$MaxStringLength)
				set sc = ##class(isc.py.Callout).StreamWrite(codePiece)
				quit:$$$ISERR(sc)
			}
		} else {
			set sc = ##class(isc.py.Callout).StreamWrite(code)
			quit:$$$ISERR(sc)
		}
		quit:$$$ISERR(sc) sc
		set sc = ##class(isc.py.Callout).StreamExecute()
	} else {		
		set tempCode = $select(hasVar : variable _ "=", 1:"")
		if $isObject(code) {
			set tempCode = tempCode _ code.Read($$$MaxStringLength)
		} else {
			set tempCode = tempCode _ code
		}
		
		do ##class(isc.py.Callout).SimpleString(tempCode)
	}
	
	set sc = $$$ADDSC(sc, ..GetStatus())
	
	quit sc
}

/// Populate variable from sql query
/// variable - python variable to set
/// type - variable type (Currently supported: dataframe (pandas dataframe) and list.
/// query - text of the SQL query
/// set sc = ##class(isc.py.Main).ExecuteQuery("SELECT * FROM isc_py_test.CannibalizationData", "df")
ClassMethod ExecuteQuery(query As %String, variable, type As %String(VALUELIST=",dataframe,list") = "list") As %Status
{
	#include %occODBC
	#dim sc As %Status = $$$OK	
	quit:",dataframe,list"'[type $$$ERROR($$$GeneralError, "Invalid type: " _ $g(type) _ ". Expected types: dataframe or list")
	
	if type="dataframe" {
		set sc = ..ImportModule("pandas", , .pandas)
		quit:$$$ISERR(sc) sc
	}
	
	/// Really %sqlcq.<NAMESPACE>.cls<NUMBER>
	#dim result As %SQL.ISelectResult
	set result = ##class(%SQL.Statement).%ExecDirect(,query)

	set start = $zh
	#dim metadata As SQL.StatementMetadata
	set metadata = result.%GetMetadata()
	set columnCount = metadata.columns.Count()
	
	set columnList = ""
	for i=1:1:columnCount {
		#dim column As %SQL.StatementColumn
		set column = metadata.columns.GetAt(i)
		
		set class(i) = $lb(column.colName)
		if column.IsNumeric() {
			set class(i) = class(i) _ $lb("numeric")
		} elseif ((column.ODBCType=$$$ODBCTYPEtimestamp) || (column.ODBCType=$$$ODBCTYPEdate)) {
			set class(i) = class(i) _ $lb("date")
		} elseif column.ODBCType = $$$ODBCTYPEtime  {
			set class(i) = class(i) _ $lb("time")
		} else {
			set class(i) = class(i) _ $lb("string")
		}
		
		set columnList = columnList _ $lb("'" _ column.colName _ "'")
	}
	
	// zzzcolumns = ['col1', 'col2', 'col3']
	if type="dataframe" { 
		set code = "zzzcolumns=[" _ $lts(columnList, ",") _ "]"
	} elseif type="list" {
		set code = "zzzcolumns=[(" _ $lts(columnList, ",") _ ")]"
	}
	set sc = ..SimpleString(code)
	quit:$$$ISERR(sc) sc
	
	set data = ##class(%Stream.GlobalCharacter).%New()
	do data.Write("[")
	
	set first = $$$YES
	while result.%Next() {		
		// TODO get isLastRow in a sane way
		if first {
			set first = $$$NO
		} else {
			do data.Write(",")
		}
		set rowList = ""
		for i=1:1:columnCount {
			set value = result.%GetData(i)
			set:$lv(value) value = $lts(value)
			set rowList = rowList _ $lb("'" _ value _ "'")
		}
		do data.Write("(" _	$lts(rowList, ",") _ ")")
		
	}
	do data.Write("]")
	
	set sc = ..ExcuteCode(data, "zzzdata")
	quit:$$$ISERR(sc) sc
	
	if type="dataframe" {	
		set sc = ..SimpleString(variable _ "=" _ pandas _ ".DataFrame(zzzdata, columns=zzzcolumns)")
	} elseif type="list" {
		set sc = ..SimpleString(variable _ "= zzzcolumns + zzzdata")
	}
	do ..SimpleString("del zzzdata, zzzcolumns")	
	
	set end = $zh
	write "Time: ", end-start,!
	quit sc
}

/// variable - variable name
/// useString - if variable length is less than $$$MaxStringLength, return string instead of stream. Ignored if variable length is more than $$$MaxStringLength
/// set sc = ##class(isc.py.Main).GetVariable()
ClassMethod GetVariable(variable As %String, serialization As %Integer = {##class(isc.py.Callout).#SerializationStr}, ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ..GetVariableInfo(variable, serialization, .defined, .type, .length)
	quit:$$$ISERR(sc) sc
	quit:'defined $$$ERROR($$$GeneralError, "Variable '" _ variable _ "' is not defined")
	
	if ((length<=$$$MaxStringLength) && useString) {
		set stream = ##class(isc.py.Callout).SimpleString(, variable, serialization)
	} else {
		set:'$isObject($g(stream)) stream = ##class(%Stream.GlobalCharacter).%New()
		
		if (length<=$$$MaxStringLength) {
			set zzzvar = ##class(isc.py.Callout).SimpleString(, variable, serialization)
			do stream.Write(zzzvar)
		} else {
			set step = $$$MaxStringLength
			for i=0:step:length+1 {
				if serialization = ##class(isc.py.Callout).#SerializationRepr {
					set zzzvar = ##class(isc.py.Callout).SimpleString("zzzvar=repr(" _ variable _ ")[" _ i _ ":" _ (i + step) _ "]", "zzzvar")
				} else {
					set zzzvar = ##class(isc.py.Callout).SimpleString("zzzvar=" _ variable _ "[" _ i _ ":" _ (i + step) _ "]", "zzzvar", serialization)
				}
				do stream.Write(zzzvar)
			}
			do ##class(isc.py.Callout).SimpleString("del zzzvar")
		}
		set sc = stream.%Save()
		do stream.Rewind()
	}
	
	set sc = $$$ADDSC(sc, ..GetStatus())
	
	quit sc
}

/// Get variable metainformation.
/// variable - variable name
/// serialization - serialization type. See isc.py.Callout Serialization* parameters for details
/// defined - is variable defined
/// type - variable type
/// length - length (in symbols) of variable chosen serialization
/// set sc = ##class(isc.py.Main).GetVariableInfo()
ClassMethod GetVariableInfo(variable As %String = "", serialization As %Integer = {##class(isc.py.Callout).#SerializationStr}, Output defined As %Boolean, Output type As %String, Output length As %String) As %Status
{
	#dim sc As %Status = $$$OK
	kill defined, type, length
	
	quit:variable="" $$$ERROR($$$GeneralError, "Variable argument should be set")
	set defined = ##class(isc.py.Callout).SimpleString("zzzdef='" _ variable _ "' in vars() or '" _ variable _ "' in globals()", "zzzdef")
	set defined = $case(defined, "True":$$$YES, "False":$$$NO, :"")
	
	if defined {	
		set type = ##class(isc.py.Callout).SimpleString("zzztype=type(" _ variable _ ").__name__", "zzztype")

		if serialization = ##class(isc.py.Callout).#SerializationRepr {
			set length = ##class(isc.py.Callout).SimpleString("zzzlen=len(repr(" _ variable _ "))", "zzzlen")
		} else {
			set length = ##class(isc.py.Callout).SimpleString("zzzlen=len(str(" _ variable _ "))",  "zzzlen")
		}
		
		do ..SimpleString("del zzztype, zzzlen")
	}
	
	do ..SimpleString("del zzzdef")
	set sc = ..GetStatus()
	
	quit sc
}

/// Import module with alias.
/// If module is already imported, imported value would be set to 1 and alias to existing alias.
/// If module is already imported, actual import would be skipped
ClassMethod ImportModule(module As %String, Output imported As %Boolean, Output alias As %String) As %Status
{
	kill imported
	set sc = ..GetModuleInfo(module, .imported, .existingAlias)
	quit:$$$ISERR(sc) sc
	
	if imported {
		set alias = existingAlias
	} else {
		if $g(alias)'="" {
			set sc = ..SimpleString("import " _ module _ " as " _ alias)
		} else {
			set sc = ..SimpleString("import " _ module)
			set alias = module
		}
	}
	
	quit sc
}

/// Get information about modules.
/// If it was imported without alias, then alias is the module name
/// set sc = ##class(isc.py.Main).GetModuleInfo("", .imported, .alias)
ClassMethod GetModuleInfo(module As %String, Output imported As %Boolean, Output alias As %String) As %Status
{
	#dim sc As %Status = $$$OK
	kill imported, alias
	
	quit:module="" $$$ERROR($$$GeneralError, "Module argument should be set")
	set imported = ##class(isc.py.Callout).SimpleString("zzzdef='" _ module _ "' in dir()", "zzzdef")
	set imported = $case(imported, "True":$$$YES, "False":$$$NO, :"")
	
	if imported {
		do ..SimpleString("import types")
		do ##class(isc.py.Callout).SimpleString("def zzzgetalias(module):" _ $c(10) _ 
												"    for name, val in globals().items():" _ $c(10) _ 
												"        if isinstance(val, types.ModuleType):" _ $c(10) _ 
												"            if val.__name__ == module:" _ $c(10) _ 
												"                return name" _ $c(10) _ 
												"    return None")
		
		set alias = ##class(isc.py.Callout).SimpleString("zzzalias=zzzgetalias('" _ module _ "')", "zzzalias")
		do ..SimpleString("del zzzalias")
	}
	
	do ..SimpleString("del zzzdef")
	set sc = ..GetStatus()
	quit sc
}

/// Returns last occured exception in Python and clears it
/// zwrite ##class(isc.py.Main).GetStatus()
ClassMethod GetStatus() As %Status
{
	do ##class(isc.py.Callout).SimpleString("import sys, traceback")
	set haxExc = ##class(isc.py.Callout).SimpleString("zzzerr = hasattr(sys, 'last_type')", "zzzerr")
	do ##class(isc.py.Callout).SimpleString("del zzzerr")
	quit:haxExc="False" $$$OK
	
	set excText = ##class(isc.py.Callout).SimpleString("zzzerr = traceback.format_exception(sys.last_type, sys.last_value, sys.last_traceback)", "zzzerr")
	set excText = $zcvt($zcvt(excText, "I", "UTF8"), "I", "JSON")
	do ##class(isc.py.Callout).SimpleString("del zzzerr, sys.last_type, sys.last_value, sys.last_traceback")
	
	quit $$$ERROR($$$GeneralError, excText)
}

/// Returns last occured exception in Python and clears it
/// zwrite ##class(isc.py.Main).GetVariableJson()
ClassMethod GetVariableJson(variable As %String, ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}) As %Status
{
	set sc = ..GetVariableInfo(variable, ##class(isc.py.Callout).#SerializationStr, .defined, .type, .length)
	quit:$$$ISERR(sc) sc
	quit:'defined $$$ERROR($$$GeneralError, "Variable '" _ variable _ "' is not defined")
	
	do ##class(isc.py.Callout).SimpleString("import json")
	do ##class(isc.py.Callout).SimpleString("def zzzempty(obj):" _ $c(10) _ "    return ''")
	
	if type = "DataFrame" {
		set sc = ..ExcuteCode(variable _ ".to_json()", "zzzjson")
	/*} elseif type="DatetimeIndex" { TODO*/
	} else {
		set sc = ..ExcuteCode("json.dumps(" _variable _ ", default=zzzempty)", "zzzjson")
	}
	if $$$ISOK(sc) {
		set sc = ##class(isc.py.Main).GetVariable("zzzjson", ##class(isc.py.Callout).#SerializationStr, .stream, useString)
		do ..SimpleString("del zzzjson")
		
		if $$$ISOK(sc) {
			if $isObject(stream) {
				if (stream.Size=2) {
					set content = stream.Read()
					do:content="""""" stream.Clear()
					do stream.%Save()
					do stream.Rewind()
				}	
			} else {
				set:stream="""""" stream = ""
			} 	
		}
	}
	
	if $$$ISERR(sc) {
		if useString {
			set stream = ""
		} else {
			if $isObject($g(stream)) {
				do stream.Clear()
				do stream.%Save()
				do stream.Rewind()
			} else {
				set stream = ##class(%Stream.GlobalCharacter).%New()
			}
		}
	}
	quit sc
}

/// Get Variable Pickle form
/// zwrite ##class(isc.py.Main).GetVariableJson()
ClassMethod GetVariablePickle(variable As %String, ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}) As %Status
{
	set sc = ..GetVariableInfo(variable, ##class(isc.py.Callout).#SerializationStr, .defined, .type, .length)
	quit:$$$ISERR(sc) sc
	quit:'defined $$$ERROR($$$GeneralError, "Variable '" _ variable _ "' is not defined")

	do ##class(isc.py.Callout).SimpleString("import pickle;")
	
	set sc = ##class(isc.py.Main).ExcuteCode("pickle.dumps(" _ variable _ ")", "zzzpickle")
	if $$$ISOK(sc) {
		set sc = ##class(isc.py.Main).GetVariable("zzzpickle", ##class(isc.py.Callout).#SerializationStr, .stream, useString)
		do ##class(isc.py.Callout).SimpleString("del zzzpickle")
	}

	if $$$ISERR(sc) {
		if useString {
			set stream = ""
		} else {
			if $isObject($g(stream)) {
				do stream.Clear()
				do stream.%Save()
				do stream.Rewind()
			} else {
				set stream = ##class(%Stream.GlobalCharacter).%New()
			}
		}
	}
	quit sc
}

}

