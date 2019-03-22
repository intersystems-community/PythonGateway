/// Dynamic Python object
Class isc.py.gw.DynamicObject Extends %RegisteredObject
{

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
		set sc = ##class(isc.py.Main).GetVariableInfo(variable, ,.defined, .type)
		throw:'defined ##class(%Exception.General).%New("<VARIABLE>", variable)
		set ..%Type = $g(type)
	}
	
	quit sc
}

/// Get serialized property value
Method %DispatchGetProperty(property As %String) [ ServerOnly = 1 ]
{
	$$$TOE(sc, ##class(isc.py.Main).GetVariableInfo(..%Variable _ "." _ property, ..%Serialization, .defined, .type, .length))
	throw:'defined ##class(%Exception.General).%New("<PROPERTY>", property)
	
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
	//$$$TOE(sc, ##class(isc.py.Main).GetVariableInfo(..%Variable _ "." _ property, ..%Serialization, .defined, .type, .length))
	//throw:'defined ##class(%Exception.General).%New("<PROPERTY>", property)
	
	if ($isObject(val) && val.%Extends("isc.py.gw.DynamicObject")) {
		set value = val.%Variable
	} elseif (..%EscapeOnSet) {
		set value = ##class(isc.py.util.Converter).EscapeString(val)
	} else {
		set value = val
	}
	set arguments = $lb(..%Variable, ##class(isc.py.util.Converter).EscapeString(property), value)
	
	$$$TOE(sc, ##class(isc.py.Main).ExecuteFunction("setattr", arguments))
}

/// Call python method
Method %DispatchMethod(method As %String, args...) [ ServerOnly = 1 ]
{
	for i=1:1:$g(args) {
		set val = args(i)
		if ($isObject(val) && val.%Extends("isc.py.gw.DynamicObject")) {
			set value = val.%Variable
		} elseif (..%EscapeOnCall) {
			set value = ##class(isc.py.util.Converter).EscapeString(val)
		} else {
			set value = val
		}
		
		set args(i) = value
	}
	
	set variable = "variable" _ $random(100000000)
	
	$$$TOE(sc, ##class(isc.py.Main).ExecuteFunctionArgs(..%Variable _ "." _ method, variable ,..%Serialization, .result, args...))
	
	$$$TOE(sc, ##class(isc.py.Main).GetVariableInfo(variable, , .defined, .type))
	
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

}

