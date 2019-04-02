/// Dynamic Python object
Class isc.py.gw.DynamicObject Extends %RegisteredObject
{

/// Automatically escape values on  method call
Parameter EscapeOnCall As %Boolean = {$$$NO};

/// Name of python variable holding the object
Property %Variable As %String(MAXLEN = 1000);

/// Python type
Property %Type As %String(MAXLEN = 1000);

/// Default serialization for methods
Property %Serialization As %Integer [ InitialExpression = {##class(isc.py.Callout).#SerializationStr} ];

/// Automatically escape values on property set
Property %EscapeOnSet As %Boolean [ InitialExpression = {$$$YES} ];

/// Automatically escape values on method call
Property %EscapeOnCall As %Boolean [ InitialExpression = {$$$NO} ];

/// do ##class(isc.py.init.Test).Initialize(,1)
/// set obj = ##class(isc.py.gw.DynamicObject).%New("Person", "p1", , "'Ed'", "25", "'Test'")
/// w obj.name
/// s obj.name="Bob"
/// w obj.name
/// w obj.age
/// w obj.getAge()
/// w obj.getAgePlus(10)
Method %OnNew(type As %String = "", variable As %String, args...) As %Status [ Private, ServerOnly = 1 ]
{
	set ..%Variable = variable
	
	if type'="" {
		// Create variable of type
		set ..%Type = type
		set sc = ##class(isc.py.Main).ExecuteFunctionArgs(type, variable,,, args...)
	} else {
		// Populate variable info
		set sc = ##class(isc.py.Main).GetVariableDefined(variable, .defined)
		throw:'defined ##class(%Exception.General).%New("<VARIABLE>", variable)
		set ..%Type = $g(type)
	}
	
	quit sc
}

/// Get serialized property value
Method %DispatchGetProperty(property As %String) [ ServerOnly = 1 ]
{
	$$$TOE(sc, ##class(isc.py.Main).GetVariableDefined(..%Variable _ "." _ property, .defined))
	throw:'defined ##class(%Exception.General).%New("<PROPERTY>", property)
	
	$$$TOE(sc, ##class(isc.py.Main).GetVariableType(..%Variable _ "." _ property, .type))
	
	if ..%IsPrimitive(type) = $$$YES {
		$$$TOE(sc, ##class(isc.py.Main).SimpleString("zzzproperty=" _ ..%Variable _ "." _ property, "zzzproperty", ..%Serialization, .zzzproperty))
		$$$TOE(sc, ##class(isc.py.Main).SimpleString("del zzzproperty"))
	} else {
		set zzzproperty = ..%New(, ..%Variable _ "." _ property)
	}
	
	quit zzzproperty
}

/// Set python object property
Method %DispatchSetProperty(property As %String, val) [ ServerOnly = 1 ]
{
	set value = ..%EscapeArg(val, ..%EscapeOnSet)
	set arguments = $lb(..%Variable, ##class(isc.py.util.Converter).EscapeString(property), value)
	
	$$$TOE(sc, ##class(isc.py.Main).ExecuteFunction("setattr", arguments))
}

/// Call python method
Method %DispatchMethod(method As %String, args...) [ ServerOnly = 1 ]
{
	for i=1:1:$g(args) {
		if $d(args(i)) {
			set value = ..%EscapeArg(args(i), ..%EscapeOnCall)
			set args(i) = value
		}
	}
	
	set variable = ..%GetNewVar()
	
	$$$TOE(sc, ##class(isc.py.Main).ExecuteFunctionArgs(..%Variable _ "." _ method, variable ,..%Serialization, .result, args...))
	
	$$$TOE(sc, ##class(isc.py.Main).GetVariableType(variable, .type))
	
	if ..%IsPrimitive(type) = $$$NO {
		set result = ..%New(,variable)
	}
	
	quit result
}

/// Convert Python object to JSON
Method %ToJSON(ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}) As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).GetVariableJson(..%Variable, .stream, useString)
}

/// Convert Python object to InterSystems IRIS Dynamic object
Method %ToDynObj(Output obj As %DynamicObject) As %Status
{
	set sc = ..%ToJSON(.stream)
	quit:$$$ISERR(sc) sc
	try {
		set obj = {}.%FromJSON(stream)
	} catch ex {
		set sc = ex.AsStatus()
	}
	
	quit sc
}

/// Convert Python object to Pickle or Dill
Method %ToPickle(ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}, useDill As %Boolean = {$$$NO}) As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).GetVariablePickle(..%Variable, .stream, useString, useDill)
}

/// Convert Python object to string
Method %ToStream(ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}) As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).GetVariable(..%Variable, ..%Serialization, .stream, useString)
}

Method %Destroy() [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString("del " _ ..%Variable)
}

/// Get object as serialized string
Method %GetString() As %String
{
	set sc = ..%ToStream(.stream, $$$YES)
	quit:$$$ISERR(sc) ""
	if $isObject(stream) {
		set stream = stream.Read($$$MaxStringLength)
	}
	
	quit stream
}

/// Get object as serialized JSON string
Method %GetJSON() As %String
{
	set sc = ..%ToJSON(.stream, $$$YES)
	quit:$$$ISERR(sc) ""
	if $isObject(stream) {
		set stream = stream.Read($$$MaxStringLength)
	}
	
	quit stream
}

/// Primitive types are returned serialized.
/// For non-primitive types ProxyObject is returned.
ClassMethod %IsPrimitive(type As %String) As %Boolean
{
	quit:$lf($lb("str", "int", "bool", "float"), type)>0 $$$YES
	quit $$$NO
}

/// Convert incoming args argument to string.
/// args can be one of:
/// - $lb(val1, val2, ..., valN) 
/// - any %Collection.AbstractIterator class 
/// - Dynamic array
/// - singular value
ClassMethod %ArgsToString(args) As %String
{
	quit:'$d(args) ""
	
	if $isObject(args) {
		if args.%Extends("%Collection.AbstractIterator") {
			set args = $lts(##class(isc.py.util.Converter).CollectionToList(args))
		} elseif args.%Extends("%Library.DynamicAbstractObject") {
			set args = $lts(##class(isc.py.util.Converter).DynamicToList(args))
		} else {
			throw ##class(%Exception.General).%New("<PGTW>:%ArgsToString", args)
		}
	}
	
	if (($listvalid(args)) && ($ll(args)>0)) {
		for i=1:1:$ll(args) {
			set $li(args, i) = ..%EscapeArg($lg(args, i), ..#EscapeOnCall)
		}
		set result = $lts(args)
	} else {
		set result = ..%EscapeArg(args, ..#EscapeOnCall)
	}
	quit result
}

/// Convert incoming kwargs argument to string.
/// kwargs can be one of:
/// - $lb($lb(name1, val1), $lb(name2, val2), ..., $lb(nameN, valN)) 
/// - any %Collection.AbstractArray class 
/// - flat Dynamic object
/// - singular key=value pair  
ClassMethod %KWArgsToString(args) As %String
{
	quit:'$d(args) ""
	
	if $isObject(args) {
		if args.%Extends("%Collection.AbstractIterator") {
			set args = $lts(##class(isc.py.util.Converter).CollectionToList(args, $$$YES))
		} elseif args.%Extends("%Library.DynamicAbstractObject") {
			return "**" _ args.%ToJSON()
		} else {
			throw ##class(%Exception.General).%New("<PGTW>:%KWArgsToString", args)
		}
	}
	
	if (($listvalid(args)) && ($ll(args)>0)) {
		set argsComputed = ""
		for i=1:1:$ll(args) {
			set arg = $lg(args, i)
			set argsComputed = argsComputed _ $lb($lg(arg) _ "=" _ ..%EscapeArg($lg(arg,2), ..#EscapeOnCall))
		}
		set result = $lts(argsComputed)
	} else {
		// We don't want to escape singular key=value expression
		set result = args
	}
	quit result
}

/// Convert args... to string
/// w ##class(isc.py.gw.DynamicObject).%CallArgsToString()
ClassMethod %CallArgsToString(args...) As %String
{
	quit:'$d(args) ""
	
	#dim firstArg As %Boolean = $$$YES
	
	set result = ""
	for i=1:1:args {
		if $d(args(i)) {
			set value = ..%EscapeArg(args(i))
		} else {
			set value = ""
		}
		
		set result = result _ $case(firstArg, $$$YES:"", :", ") _ value
		set firstArg = $$$NO
	}
	
	quit result
}

/// Escape one argumet if needed
/// w ##class(isc.py.gw.DynamicObject).%EscapeArg()
ClassMethod %EscapeArg(arg, escapeString As %Boolean = {..#EscapeOnCall}) As %String
{
	quit:'$d(arg) ""
	
	if ($isObject(arg) && arg.%Extends("isc.py.gw.DynamicObject")) {
		set value = arg.%Variable
	} elseif escapeString {
		set value = ##class(isc.py.util.Converter).EscapeString(arg)
	} else {
		set value = arg
	}

	quit value
}

/// Get unused Python variable
/// w ##class(isc.py.gw.DynamicObject).%GetNewVar()
ClassMethod %GetNewVar() [ CodeMode = expression ]
{
"variable" _ $random(100000000000000000)
}

/// Convert python type to InterSystems IRIS class
/// w ##class(isc.py.gw.DynamicObject).%TypeToClass
ClassMethod %TypeToClass(type) As %String
{
	set basePackage = $p($classname(), ".", 1)
	set class = basePackage _ "." _ type
	
	if '##class(%Dictionary.CompiledClass).%ExistsId(class) {
		set class = $classname()
	}
	
	quit class
}

}

