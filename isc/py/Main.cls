/// Public entry point to call Python.
/// Also may be refernced as API or Terminal API.
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
	#dim sc1 As %Status = $$$OK
	#dim sc2 As %Status = $$$OK
	
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
	
	set sc1 = ..GetStatus()
	
	set:$$$ISERR(sc1) sc2 = $$$ERROR($$$GeneralError, $$$FormatText("code: %1, variable: %2, serialization: %3, result: %4", $replace(code, $c(10), $$$NL), variable, serialization, $g(result)))
	
	set sc = $$$ADDSC(sc2, $$$ADDSC(sc, sc1))
	
	quit sc
}

/// Executes code. If variable is not empty sets variable=code.
/// If variable is undefined just executes the code
/// code may be a string or a stream
/// write ##class(isc.py.Main).ExecuteCode()
ClassMethod ExecuteCode(code As %Stream.Object, variable As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	quit:$d(code)'=1 $$$ERROR($$$GeneralError, "Code argument should be set to stream or to string") 
	
	if $isObject(code) {
		do code.Rewind()
		set codeLength = code.Size
	} else {
		set codeLength = $l(code)
	}
	
	#dim hasVar As %Boolean = $l(variable)>0
	
	// length of code + length of var name + 1 char for '='
	set length = codeLength + $select(hasVar :$l(variable) + 1, 1:0)

	
	if length>($$$MaxStringLength \ 2) {
		set sc = ##class(isc.py.Callout).StreamInit(length)
		quit:$$$ISERR(sc) sc
		set:hasVar sc = ##class(isc.py.Callout).StreamWrite(variable _ "=")
		quit:$$$ISERR(sc) sc
		
		if $isObject(code) {
			while 'code.AtEnd {
				set codePiece = code.Read($$$MaxStringLength \ 2)
				set sc = ##class(isc.py.Callout).StreamWrite(codePiece)
				quit:$$$ISERR(sc)
			}
		} else {
			set sc = ##class(isc.py.Callout).StreamWrite(code)
			quit:$$$ISERR(sc)
		}
		quit:$$$ISERR(sc) sc
		set sc = ##class(isc.py.Callout).StreamExecute()
		set sc = $$$ADDSC(sc, ..GetStatus())
	} else {
		set tempCode = $select(hasVar : variable _ "=", 1:"")
		if $isObject(code) {
			set tempCode = tempCode _ code.Read($$$MaxStringLength)
		} else {
			set tempCode = tempCode _ code
		}
		
		set sc = ..SimpleString(tempCode)
	}
	
	if $$$ISERR(sc) {
		if $isObject(code) {
			do code.Rewind()
			set errorCode = code.Read(1000)
		} else {
			set errorCode = $e(code, 1, 1000)
		}
		set sc = $$$ADDSC(sc, $$$ERROR($$$GeneralError, $$$FormatText("code: %1, variable: %2", $replace(errorCode, $c(10), $$$NL), variable)))
	}
	
	
	quit sc
}

/// Populate variable from sql query
/// variable - python variable to set
/// type - variable type (Currently supported: dataframe (pandas dataframe) and list.
/// query - text of the SQL query
/// namespace - namespace to execute query in. 'isc.py' package must be available in this namespace.
/// Pandas is imported automatically if required.
/// set sc = ##class(isc.py.Main).ExecuteQuery("SELECT * FROM isc_py_test.CannibalizationData", "df")
ClassMethod ExecuteQuery(query As %String, variable As %String, type As %String(VALUELIST=",dataframe,list") = "list", namespace As %String = {$namespace}) As %Status
{
	#include %occODBC
	#dim sc As %Status = $$$OK	
	quit:",dataframe,list"'[type $$$ERROR($$$GeneralError, "Invalid type: " _ $g(type) _ ". Expected types: dataframe or list")
	
	if type="dataframe" {
		set sc = ..ImportModule("pandas", , .pandas)
		quit:$$$ISERR(sc) sc
	}
	set sc = ..ImportModule("datetime", , .datetime)
	quit:$$$ISERR(sc) sc

	new $namespace
	set oldNamespace = $namespace
	set $namespace = namespace
	
	set st =  ##class(%SQL.Statement).%New()
	set st.%SelectMode = 1 // ODBC
	set sc = st.%Prepare(query)
	quit:$$$ISERR(sc) sc
	
	#dim result As %SQL.StatementResult
	set result = st.%Execute()
	quit:result.%SQLCODE'=0 $$$ERROR($$$SQLError, result.%SQLCODE, result.%Message)

	#dim metadata As SQL.StatementMetadata
	set metadata = result.%GetMetadata()
	set columnCount = metadata.columns.Count()
	
	set columnList = ""
	set typeList = ""
	for i=1:1:columnCount {
		#dim column As %SQL.StatementColumn
		set column = metadata.columns.GetAt(i)
		
		if (column.IsNumeric() || (column.ODBCType = $$$ODBCTYPEnumeric)) {
			set typeList = typeList _ $lb($$$ODBCTYPEnumeric)
		} elseif (column.ODBCType=$$$ODBCTYPEtimestamp) {
			set typeList = typeList _ $lb($$$ODBCTYPEtimestamp)
		} elseif (column.ODBCType=$$$ODBCTYPEdate) {
			set typeList = typeList _ $lb($$$ODBCTYPEdate)
		} elseif column.ODBCType = $$$ODBCTYPEtime  {
			set typeList = typeList _ $lb($$$ODBCTYPEtime)
		} elseif column.clientType = 16 {
			// boolean
			set typeList = typeList _ $lb($$$ODBCTYPEbit)
		} else {
			set typeList = typeList _ $lb($$$ODBCTYPEvarchar)
		}
		
		set columnList = columnList _ $lb("'" _ column.colName _ "'")
	}
	
	set dataStr = ""
	set data = ##class(%Stream.TmpCharacter).%New()
	do data.Write("[")
	
	set first = $$$YES
	while result.%Next() {		
		set rowList = ""
		for i=1:1:columnCount {
			set value = result.%GetData(i)
			set:$lv(value) value = $lts(value)
			
			set colType = $lg(typeList, i)
			if colType = $$$ODBCTYPEbit {
				set rowList = rowList _ $lb(##class(isc.py.util.Converter).BooleanToPython(value))
			} elseif colType = $$$ODBCTYPEnumeric {
				set:value="" value = "None"
				set rowList = rowList _ $lb(value)
			} elseif colType = $$$ODBCTYPEtimestamp {
				set rowList = rowList _ $lb(##class(isc.py.util.Converter).ODBCTimeStampToPython(datetime, value))
			} elseif colType = $$$ODBCTYPEdate {
				set rowList = rowList _ $lb(##class(isc.py.util.Converter).ODBCDateToPython(datetime, value))
				// TODO Python 3.7 added date.fromisoformat("YYYY-MM-DD")
			} elseif colType = $$$ODBCTYPEtime {
				set rowList = rowList _ $lb(##class(isc.py.util.Converter).ODBCTimeToPython(datetime, value))
			} else {
				set rowList = rowList _ $lb(##class(isc.py.util.Converter).EscapeString(value))
			}
		}
		
		// TODO get isLastRow in a sane way
		if first {
			set first = $$$NO
			set dataStr = dataStr _ "(" _	$lts(rowList, ",") _ ")"
		} else {
			set dataStr = dataStr _ ",(" _	$lts(rowList, ",") _ ")"
		}
		
		if $l(dataStr)>3000000 {
			do data.Write(dataStr)
			set dataStr=""
		}
			
	}
	do data.Write(dataStr)
	do data.Write("]")

	set $namespace = oldNamespace

	set sc = ..ExecuteCode(data, variable)
	quit:$$$ISERR(sc) sc

	// zzzcolumns = ['col1', 'col2', 'col3']
	if type="dataframe" { 
		set code = "zzzcolumns=[" _ $lts(columnList, ",") _ "]"
	} elseif type="list" {
		set code = "zzzcolumns=[(" _ $lts(columnList, ",") _ ")]"
	}
	
	set sc = ..SimpleString(code)
	quit:$$$ISERR(sc) sc
	
	if type="dataframe" {
		set sc = ..SimpleString(variable _ "=" _ pandas _ ".DataFrame(" _ variable _ ", columns=zzzcolumns)")
	} elseif type="list" {
		set sc = ..SimpleString(variable _ "= zzzcolumns + " _ variable)
	}
	quit:$$$ISERR(sc) sc

	set sc = ..SimpleString("del zzzcolumns")	
	
	quit sc
}

/// Transfer global to Python list of tuples or pandas dataframe.
/// Global must be in this format: ^global(key) = $lb(field1, ... ,fieldN)
/// global - name of global
/// variable - list/dataframe name
/// type - create list or dataframe
/// start - starting global key. Must be integer.
/// end - final global key. Must be integer.
/// mask - string, mask for global values. Must be less or equal in length to the number of global value fields.
/// labels - %List of column names, first element is key column name. Therefore: List length is mask symbol length + 1.
/// How to format mask:
///   + use field as is
///   - skip field
///   b - boolean (0 - False, everything else - True)
///   d - date (from $horolog, on Windows only from 1970, on Linux from 1900)
///   t - time ($horolog, seconds since midnight) 
///   m - (moment) timestamp string in YEAR-MONTH-DAY HOUR:MINUTE:SECOND format.
/// 
/// set sc = ##class(isc.py.Main).ExecuteGlobal("BDZ4.DfXU.1", "df")
ClassMethod ExecuteGlobal(global As %String, variable As %String, type As %String(VALUELIST=",dataframe,list") = "list", start As %Integer = 1, end As %Integer = "", mask As %String, labels As %List = "", namespace As %String = {$namespace}) As %Status
{
	#dim sc As %Status = $$$OK
	quit:",dataframe,list"'[type $$$ERROR($$$GeneralError, "Invalid type: " _ $g(type) _ ". Expected types: dataframe or list")

	if type="dataframe" {
		set sc = ..ImportModule("pandas", , .pandas)
		quit:$$$ISERR(sc) sc
	}
	
	// remove ^ if any
	set:$e(global)="^" global = $e(global, 2, *)
	
	new $namespace
	set oldNamespace = $namespace
	set $namespace = namespace
	
	// set last global key as iteration end
	if end="" {
		set glvn = "^" _ global
		set end = $o(@glvn@(""),-1)
	}
		
	set sc = ##class(isc.py.Callout).GetGlobalOrder(global, start, end, mask, variable)
	quit:$$$ISERR(sc) sc
	set $namespace = oldNamespace
	
	if labels = "" {
		for i=1:1:$l(mask) {
			set labels = $lb(i) 
		}
	}
		
	set sc = ##class(isc.py.Main).SimpleString("zzzcolumns=[" _ $lts(##class(isc.py.util.Converter).EscapeStringList(labels))_ "]")
	quit:$$$ISERR(sc) sc
	
	if type="dataframe" {
		set sc = ..SimpleString(variable _ "=" _ pandas _ ".DataFrame(" _variable _ ", columns=zzzcolumns)")
	} elseif type="list" {
		set sc = ..SimpleString(variable _ "= zzzcolumns + " _ variable)
	}
	quit:$$$ISERR(sc) sc
	
	set sc = ..SimpleString("del zzzcolumns")	
	
	quit sc
}

/// Transfer class data to Python list of tuples or pandas dataframe
/// class - name of class
/// variable - list/dataframe name
/// type - list or dataframe
/// start - starting object id, defaults to 1.
/// end - final object id, defaults to last object id available.
/// properties - comma-separated list of properties to form dataframe from. * and ? wildcards are supported. 
/// 			 Defaults to * (all properties). %%CLASSNAME property is ignored. Only stored properties are used.
/// namespace - class namespace
/// 
/// set sc = ##class(isc.py.Main).ExecuteClass("User.WEB.SENTIMENTNEG", "df", "dataframe")
/// set sc = ##class(isc.py.Main).ExecuteClass("isc.py.test.CannibalizationData", "df1", "dataframe")
/// set sc = ##class(isc.py.Main).ExecuteClass("isc.py.test.Person", "dfp", "dataframe")
ClassMethod ExecuteClass(class As %String, variable As %String, type As %String(VALUELIST=",dataframe,list") = "list", start As %Integer = 1, end As %Integer = "", properties As %String = "*", namespace As %String = {$namespace}) As %Status
{
	#dim sc As %Status = $$$OK
	quit:",dataframe,list"'[type $$$ERROR($$$GeneralError, "Invalid type: " _ $g(type) _ ". Expected types: dataframe or list")
	quit:'##class(%Dictionary.CompiledClass).%ExistsId(class) $$$ERROR($$$GeneralError, "Class does not exist: " _ $g(class))
	quit:'$$$classIsPersistent(class) $$$ERROR($$$GeneralError, "Class is not persistent: " _ $g(class))
	
	if type="dataframe" {
		set sc = ..ImportModule("pandas", , .pandas)
		quit:$$$ISERR(sc) sc
	}
	
	new $namespace
	set oldNamespace = $namespace
	set $namespace = namespace
	
	set mask = ""
	set labels = ""
	set storageName = $$$comClassKeyGet(class,$$$cCLASSstoragestrategy)
	set defaultData = $$$comStorageSubMemberNext(class,$$$cCLASSstorage,storageName,$$$cSDEFdata,"")

	set dataValue = $$$comStorageSubSubMemberNext(class,$$$cCLASSstorage,storageName,$$$cSDEFdata,defaultData,$$$cSDEFDATAvalue,"")
	while dataValue'="" {
		set property = $$$comStorageSubSubMemberKeyGet(class,$$$cCLASSstorage,storageName,$$$cSDEFdata,defaultData,$$$cSDEFDATAvalue,dataValue,$$$cSDEFDATAVALvalue)
		set isCollection = ($$$comMemberKeyGet(class,$$$cCLASSproperty,property,$$$cPROPcollection)'="")
		set propertyType = $$$comMemberKeyGet(class,$$$cCLASSproperty,property,$$$cPROPtype)
		if ((##class(isc.py.util.Matcher).MatchOr(property, properties)) && (property'="%%CLASSNAME") && ('isCollection) && (propertyType'="%Library.List") && (propertyType'="%Library.Binary")) {			
			if propertyType = "%Library.Date" {
				set $e(mask, dataValue) = "d"
			} elseif propertyType = "%Library.Time" {
				set $e(mask, dataValue) = "t"
			} elseif propertyType = "%Library.Boolean" {
				set $e(mask, dataValue) = "b"
			} elseif propertyType = "%Library.TimeStamp" {
				set $e(mask, dataValue) = "m"
			} else {
				set $e(mask, dataValue) = "+"
			}
			set $list(labels, dataValue) = property
		} else {
			set $e(mask, dataValue) = "-"
		}		
		set dataValue = $$$comStorageSubSubMemberNext(class,$$$cCLASSstorage,storageName,$$$cSDEFdata,defaultData,$$$cSDEFDATAvalue,dataValue)	
	}
	
	set fixedLabels = $lb("globalKey")
	set ptr=0
	while $listnext(labels, ptr, value) {
		set:$g(value)'="" fixedLabels = fixedLabels _ $lb(value)
	}
	
	
	set global = $$$comMemberKeyGet(class,$$$cCLASSstorage,storageName,$$$cSDEFdatalocation)
	quit:$d(@global)<10 $$$ERROR($$$GeneralError, "Data global is empty")

	set sc = ..ExecuteGlobal($e(global,2,*), variable, type, start, end, mask, fixedLabels, namespace)
	
	quit sc
}

/// Transfer table data to Python list of tuples or pandas dataframe
/// table - name of table
/// variable - list/dataframe name
/// type - list or dataframe
/// start - starting row id, defaults to 1.
/// end - final global key, defaults to last row id available.
/// properties - comma-separated list of CLASS properties to form dataframe from. * and ? wildcards are supported. 
/// 			 Defaults to * (all properties). %%CLASSNAME property is ignored. Only stored properties are used.
/// namespace - class namespace
/// 
/// set sc = ##class(isc.py.Main).ExecuteTable("User_WEB.SENTIMENT_NEG", "df2", "dataframe")
ClassMethod ExecuteTable(table As %String, variable As %String, type As %String(VALUELIST=",dataframe,list") = "list", start As %Integer = 1, end As %Integer = "", properties As %String = "*", namespace As %String = {$namespace}) As %Status [ CodeMode = expression ]
{
..ExecuteClass($$$GetClassNameFromIQN(table), variable, type, start, end, properties, namespace)
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
		set sc = ..SimpleString("zzzvar = " _ variable, "zzzvar", serialization, .stream)
	} else {
		set step = $$$MaxStringLength \ 2
		set:'$isObject($g(stream)) stream = ##class(%Stream.GlobalCharacter).%New()
		
		if (length<=step) {
			set sc = ..SimpleString("zzzvar = " _ variable, "zzzvar", serialization, .zzzvar)
			do stream.Write(zzzvar)
		} else {
			if serialization = ##class(isc.py.Callout).#SerializationRepr {
				set sc = ..SimpleString("zzzvar=repr(" _ variable _ ")")
			} else {
				set sc = ..SimpleString("zzzvar=" _ variable)
			}
			quit:$$$ISERR(sc) sc
				
			for i=0:step:length+1 {
				set sc = ..SimpleString("zzzvarpiece=zzzvar[" _ i _ ":" _ (i + step) _ "]", "zzzvarpiece", ##class(isc.py.Callout).#SerializationStr, .zzzvarpiece)
				quit:$$$ISERR(sc)
				do stream.Write(zzzvarpiece)
			}
			set sc = ..SimpleString("del zzzvarpiece")
		}
		quit:$$$ISERR(sc) sc
		set sc = stream.%Save()
		do stream.Rewind()
	}
	
	set sc = $$$ADDSC(sc, ..GetStatus())
	quit:$$$ISERR(sc) sc
	
	set sc = ..SimpleString("del zzzvar")
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
	

	set sc = ..GetVariableDefined(variable, .defined)
	quit:$$$ISERR(sc) sc
		
	if defined {	
		set sc = ..GetVariableType(variable, .type)
		quit:$$$ISERR(sc) sc
		
		if serialization = ##class(isc.py.Callout).#SerializationRepr {
			set sc = ..SimpleString("zzzlen=len(repr(" _ variable _ "))", "zzzlen", , .length)
		} else {
			set sc = ..SimpleString("zzzlen=len(str(" _ variable _ "))",  "zzzlen", , .length)
		}
		quit:$$$ISERR(sc) sc
		
		set sc = ..SimpleString("del zzzlen")
	}
	quit:$$$ISERR(sc) sc
	
	quit sc
}

/// Is variable defined?
/// variable - variable name
/// defined - is variable defined
ClassMethod GetVariableDefined(variable As %String = "", Output defined As %Boolean) As %Status
{
	#dim sc As %Status = $$$OK
	kill defined
	
	quit:variable="" $$$ERROR($$$GeneralError, "Variable argument should be set")
	
	if $l(variable, ".") = 1 {
		set module = "__builtins__"
		set varLocal = variable
	} else {
		set module = $p(variable, ".", 1, *-1)
		set varLocal = $p(variable, ".", *)	
	}
	
	for i=2:1:$l(module, ".") {
		set sc = ..GetVariableDefined($p(module, ".", 1, i), .defined)
		return:defined=0 sc
	}
	
	set sc = ..SimpleString("zzzdef='" _ variable _ "' in (vars() or globals()) or hasattr(" _ module _ ", '" _ varLocal _ "')", "zzzdef", , .defined)
	quit:$$$ISERR(sc) sc
	
	set defined = ##class(isc.py.util.Converter).PythonToBoolean(defined)
	
	set sc = ..SimpleString("del zzzdef")
	quit sc
}

/// Get variable type
/// variable - variable name
/// type - variable FQCN
ClassMethod GetVariableType(variable As %String = "", Output type As %String) As %Status
{
	#dim sc As %Status = $$$OK
	kill type
	quit:variable="" $$$ERROR($$$GeneralError, "Variable argument should be set")

	set sc = ..SimpleString("zzztype=('' if " _ variable _ ".__class__.__module__ is None or " _ variable _ ".__class__.__module__ == str.__class__.__module__ else " _ variable _ ".__class__.__module__ + '.') + " _ variable _ ".__class__.__name__", "zzztype", , .type)
	quit:$$$ISERR(sc) sc
	
	set sc = ..SimpleString("del zzztype")
	quit sc
}

/// Get function metainformation.
/// function - variable name
/// defined - is function defined
/// type - function or method
/// docs - function description if any
/// signature - function signature as it apperas in Python source code
/// arguments - signature parsed into JSON array: [args, varargs, varkw, defaults, kwonlyargs, kwonlydefaults, annotations]
/// getDefaults - do not replace defaults with null if true. Defaults to false.
/// see https://docs.python.org/3/library/inspect.html#inspect.getfullargspec for details 
/// also https://docs.python.org/3/glossary.html#term-parameter
/// signature and arguments can be empty - means it's a C function without Argument Clinic declaration. 
/// For details on Argument Clinic see https://stackoverflow.com/a/42225667/2425753 for details
/// set sc = ##class(isc.py.Main).GetFunctionInfo()
ClassMethod GetFunctionInfo(function As %String = "", Output defined As %Boolean, Output type, Output docs As %VarString, Output signature As %VarString, Output arguments As %VarString, getDefaults As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	kill defined, type
	
	quit:function="" $$$ERROR($$$GeneralError, "Variable argument should be set")
	set sc = ..GetVariableDefined(function, .defined)
	quit:$$$ISERR(sc) sc
	quit:'defined $$$ERROR($$$GeneralError, "Function is not defined: " _ function)
	
	set sc = ..GetVariableType(function, .type)
	quit:$$$ISERR(sc) sc
	quit:type="type" ..GetFunctionInfo(function _ ".__init__", .defined, .type, .docs, .signature, .arguments) // for classes get constructor
	
	set sc = ..SimpleString("zzziscallable=callable(" _ function _ ")", "zzziscallable", ,.iscallable)
	quit:$$$ISERR(sc) sc
	set iscallable = ##class(isc.py.util.Converter).PythonToBoolean(iscallable)	
	quit:'iscallable $$$ERROR($$$FormatText("%1 is not callable, with type: %2", function, type))
	
	if defined {
		set sc = ..ImportModule("inspect", , .inspect)
		quit:$$$ISERR(sc) sc
		set sc = ..ImportModule("json", , .json)
		quit:$$$ISERR(sc) sc
					
		set sc = ..SimpleString("zzzdocs=" _ inspect _ ".getdoc(" _ function _ ")", "zzzdocs", , .docs)
		quit:$$$ISERR(sc) sc
		set sc = ..SimpleString("del zzzdocs")
		set:docs="None" docs = ""
		
		set sc = ..SimpleString("zzzsignature=" _ inspect _ ".signature(" _ function _ ")", "zzzsignature", , .signature)
		if $$$OK {
			set sc = ..SimpleString("del zzzsignature")
		} else {
			set signature = ""
		}
		
		set sc = ..SimpleString("zzzargs=" _ inspect _ ".getfullargspec(" _ function _ ")" _ $case(getDefaults, $$$YES:"", :"._replace(defaults=None)"))
		if $$$ISOK(sc) {
			set sc = ..GetVariableJson("zzzargs", .arguments, $$$YES)
			quit:$$$ISERR(sc) sc
			
			set sc = ..SimpleString("del zzzargs")
		} else {
			// Some C defined functions do not have introspectable arguments and signature 
			// https://stackoverflow.com/a/42225667/2425753
			set arguments = ""
			set sc = $$$OK
		}
	}
	
	quit sc
}

/// Call arbitrary method or function.
/// function - name of function to invoke. Can be nested, i.e. `random.randint`
/// variable - if provided, result of function execution would be set into this python variable
/// serialization - how to serialize result
/// result - write result into this variable
/// arguments - arguments as expected with triple dot syntax. To pass kwargs pass serialized JSON preceded with "**".
/// set sc = ##class(isc.py.Main).ExecuteFunctionArgs()
ClassMethod ExecuteFunctionArgs(function As %String, variable As %String = "zzzresult", serialization As %Integer = {##class(isc.py.Callout).#SerializationStr}, Output result As %String, arguments... As %String) As %Status
{
	// We have no arguments
	quit:'$d(arguments) ..ExecuteFunction(function, , ,variable, serialization, .result)
	
	#dim sc As %Status = $$$OK
	kill defined, type
	
	set sc = ..GetFunctionInfo(function, .defined, .type, , .signature, .funcArguments)
	quit:$$$ISERR(sc) sc
		
	set positionalArguments = ""
	set keywordArguments = ""
	
	if funcArguments="" {
		set positionalArguments = ##class(isc.py.util.Converter).LocalToList(.arguments)
	} else {
		set funcArgObj = [].%FromJSON(funcArguments)
		
		#dim args As %DynamicArray = funcArgObj.%Get(0)
		#dim varargs As %String = funcArgObj.%Get(1)
		#dim varkw As %String = funcArgObj.%Get(2)
		#dim defaults As %DynamicArray = funcArgObj.%Get(3)
		#dim kwonlyargs As %DynamicArray = funcArgObj.%Get(4)
		#dim kwonlydefaults As %DynamicArray = funcArgObj.%Get(5)
		
		// Remove self argument if it's a method or a constructor function
		do:((type["method") || ($isObject(args) && (args.%Get(0)="self"))) args.%Remove(0)

		#dim posCount As %Integer = $case($isObject(args), $$$YES: args.%Size(), :0)
		#dim kwCount As %Integer = $case($isObject(kwonlyargs), $$$YES: kwonlyargs.%Size(), :0)
		#dim hasArgs As %Boolean = (varargs'="")
		#dim hasKWArgs As %Boolean = (varkw'="")
		
		// As we ignore **kwargs if any we have two options
		// if there's no *argv we get positional arguments first, keyword arguments second
		// if hasArgs is true (so *argv exist) we count keyword parameters from the end and the rest are positional
		if 'hasArgs {
			set positionalCount = posCount
		} else {
			set positionalCount = arguments - kwCount
		}
		
		for i=1:1:positionalCount {
			set positionalArguments = positionalArguments _ $lb(arguments(i))
		}
		
		set kwStartPosition = positionalCount + 1
		for i=kwStartPosition:1:positionalCount+kwCount {
			set keywordArguments = keywordArguments _ $lb($lb(kwonlyargs.%Get(i - kwStartPosition), arguments(i)))
		}
	}
		
	//zw kwCount,positionalCount,keywordCount,arguments,size,signature,funcArguments,positionalArguments, keywordArguments	
	set sc = ..ExecuteFunction(function, positionalArguments, keywordArguments, variable, serialization, .result)
	
	quit sc
}

/// Call arbitrary method or function.
/// function - name of function to invoke. Can be nested, i.e. `random.randint`  
/// positionalArguments - $lb(val1, val2, ..., valN) or any %Collection.AbstractIterator class or Dynamic array
/// keywordArguments - $lb($lb(name1, val1), $lb(name2, val2), ..., $lb(nameN, valN)) or any %Collection.AbstractArray class or flat Dynamic object 
/// variable - if provided, result of function execution would be set into this python variable
/// serialization - how to serialize result
/// result - write result into this variable
/// set sc = ##class(isc.py.Main).ExecuteFunction()
ClassMethod ExecuteFunction(function As %String, positionalArguments As %List = "", keywordArguments As %List = "", variable As %String = "zzzresult", serialization As %Integer = {##class(isc.py.Callout).#SerializationStr}, Output result As %String) As %Status
{
	#dim sc As %Status = $$$OK
	kill defined, type
	
	set sc = ..GetFunctionInfo(function, .defined, .type, , .signature, .arguments)
	quit:$$$ISERR(sc) sc
		
	set code = variable _ "=" _ function _ "("
	if (positionalArguments'="") {
		if (($listvalid(positionalArguments)) && ($ll(positionalArguments)>0)) {
			set code = code _ $lts(positionalArguments)
		} elseif $isObject(positionalArguments) {
			if positionalArguments.%Extends("%Collection.AbstractIterator") {
				set code = code _ $lts(##class(isc.py.util.Converter).CollectionToList(positionalArguments))
			} elseif positionalArguments.%Extends("%Library.DynamicAbstractObject") {
				set code = code _ $lts(##class(isc.py.util.Converter).DynamicToList(positionalArguments))
			} else {
				set sc = $$$ERROR($$$GeneralError, "positionalArguments is not a $list and not an object")
			}
		} else {
			set sc = $$$ERROR($$$GeneralError, "positionalArguments is not a $list and not an object, with value: " _ positionalArguments)
		}
	}

	if (keywordArguments'="") {
		set:$e(code,*)'="(" code = code _ ","
		
		/// $lb("key1=value1","key2=value2", ..., "keyN=valueN")
		#dim keywordArgumentsComputed As %List = ""
		
		if (($listvalid(keywordArguments)) && ($ll(keywordArguments)>0)) {
			for i=1:1:$ll(keywordArguments) {
				set keywordArgumentsComputed = keywordArgumentsComputed _ $lb($lts($lg(keywordArguments, i), "="))
			}
		} elseif $isObject(keywordArguments) {
			if keywordArguments.%Extends("%Collection.AbstractIterator") {
				set keywordArgumentsComputed = ##class(isc.py.util.Converter).CollectionToList(keywordArguments, $$$YES)
			} elseif keywordArguments.%Extends("%Library.DynamicAbstractObject") {
				set keywordArgumentsComputed = ##class(isc.py.util.Converter).DynamicToList(keywordArguments, $$$YES)
			} else {
				set sc = $$$ERROR($$$GeneralError, "keywordArguments is not a $list and not an object")
			}
		} else {
			set sc = $$$ERROR($$$GeneralError, "keywordArguments is not a $list and not an object, with value: " _ positionalArguments)
		}
		
		set code = code _ $lts(keywordArgumentsComputed)
	}
	quit:$$$ISERR(sc) sc
	
	set code = code _ ")"
	 
	set sc = ..SimpleString(code, variable, serialization, .result)
	quit:$$$ISERR(sc) sc
	
	set:variable="zzzresult" sc = ..SimpleString("del zzzresult")
	
	quit sc
}

/// Import module with alias.
/// If module is already imported, imported value would be set to 1 and alias to existing alias.
/// If module is already imported, actual import would be skipped
/// set sc = ##class(isc.py.Main).ImportModule()
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
	
	set sc = ..SimpleString("import types")
	quit:$$$ISERR(sc) sc
	set sc = ..SimpleString(  "def zzzgetalias(module):" _ $c(10) _ 
													"    for name, val in globals().items():" _ $c(10) _ 
													"        if isinstance(val, types.ModuleType):" _ $c(10) _ 
													"            if val.__name__ == module:" _ $c(10) _ 
													"                return name" _ $c(10) _ 
													"    return ''")
	quit:$$$ISERR(sc) sc
	
	set sc = ..SimpleString("zzzalias=zzzgetalias('" _ module _ "')", "zzzalias", , .alias)
	quit:$$$ISERR(sc) sc
	set sc = ..SimpleString("del zzzalias")
	
	if alias="" {
		set imported = $$$NO
	} else {
		set imported = $$$YES
	}
	
	quit sc
}

/// Returns last occured exception in Python and clears it
/// zwrite ##class(isc.py.Main).GetStatus()
ClassMethod GetStatus() As %Status
{
	try {
		#dim sc As %Status = $$$OK
		do ##class(isc.py.Callout).SimpleString("import sys, traceback")
		set haxExc = ##class(isc.py.Callout).SimpleString("zzzerr = hasattr(sys, 'last_type')", "zzzerr")
		do ##class(isc.py.Callout).SimpleString("del zzzerr")
		quit:haxExc="False"
		
		set excText = ##class(isc.py.Callout).SimpleString("zzzerr = traceback.format_exception(sys.last_type, sys.last_value, sys.last_traceback)", "zzzerr")
		set excText = $replace($zcvt(excText, "I", "JSON"), $c(10), $$$NL)
		do ##class(isc.py.Callout).SimpleString("del zzzerr, sys.last_type, sys.last_value, sys.last_traceback")
		set sc = $$$ERROR($$$GeneralError, excText)
	} catch ex {
		set sc = ex.AsStatus()
	}
	quit sc
}

/// Returns last occured exception in Python and clears it
/// zwrite ##class(isc.py.Main).GetVariableJson()
/// Can return invalid json (NaN, Infinity), see: https://stackoverflow.com/questions/28639953/python-nan-json-encoder
ClassMethod GetVariableJson(variable As %String, ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}) As %Status
{
	set stream = ""
	set sc = ..GetVariableDefined(variable, .defined)
	quit:$$$ISERR(sc) sc
	quit:'defined $$$ERROR($$$GeneralError, "Variable '" _ variable _ "' is not defined")
	
	set sc = ..SimpleString("import json")
	quit:$$$ISERR(sc) sc

	// More info https://hynek.me/articles/serialization/
	set sc = ..SimpleString("def zzztoserializable(val):" _ $c(10) _ 
							"    if hasattr(val, 'to_json'):" _ $c(10) _ 
							"        return json.loads(val.to_json())" _ $c(10) _ 
							"    elif hasattr(val, '__dict__'):" _ $c(10) _ 
							"        return val.__dict__" _ $c(10) _ 
							"    elif hasattr(val, 'for_json'):" _ $c(10) _ 
							"        return json.loads(val.for_json()) " _ $c(10) _ 
							"    elif isinstance(val, Exception):" _ $c(10) _ 
							"        return {" _ $c(10) _ 
							"            'error': val.__class__.__name__," _ $c(10) _ 
							"            'args': val.args," _ $c(10) _ 
							"        }" _ $c(10) _ 
							"    return str(val)")

	quit:$$$ISERR(sc) sc
	
	set sc = ..SimpleString("zzzjson=json.dumps(" _variable _ ", default=zzztoserializable)")
	
	if $$$ISOK(sc) {
		set sc = ..GetVariable("zzzjson", ##class(isc.py.Callout).#SerializationStr, .stream, useString)
		
		if $$$ISOK(sc) {
			do ..SimpleString("del zzzjson")
			
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
/// zwrite ##class(isc.py.Main).GetVariablePickle()
ClassMethod GetVariablePickle(variable As %String, ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}, useDill As %Boolean = {$$$NO}) As %Status
{
	set stream = ""
	set sc = ..GetVariableDefined(variable, .defined)
	quit:$$$ISERR(sc) sc
	quit:'defined $$$ERROR($$$GeneralError, "Variable '" _ variable _ "' is not defined")
	
	if useDill {
		set pickle = "dill"
	} else {
		set pickle = "pickle"
	}

	set sc = ..ImportModule(pickle, ,.pickleAlias)
	quit:$$$ISERR(sc) sc
	
	set sc = ..SimpleString("zzzpickle=" _ pickleAlias _ ".dumps(" _ variable _ ")")
	if $$$ISOK(sc) {
		set sc = ..GetVariable("zzzpickle", ##class(isc.py.Callout).#SerializationStr, .stream, useString)
		quit:$$$ISERR(sc) sc
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

