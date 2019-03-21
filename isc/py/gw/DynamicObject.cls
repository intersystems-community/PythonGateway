/// Dynamic Python object
Class isc.py.gw.DynamicObject Extends %RegisteredObject
{

/// Name of python variable holding the object
Property %Variable As %String(MAXLEN = 1000);

/// Python type
Property %Type As %String(MAXLEN = 1000);

/// Default serialization for methods
Property %Serialization As %Integer;

Property %EscapeOnSet As %Boolean [ InitialExpression = {$$$YES} ];

/// do ##class(isc.py.init.Test).Initialize(,1)
/// set obj = ##class(isc.py.gw.DynamicObject).%New("Person", "p1", , "'Ed'", "25", "'Test'")
/// w obj.name
/// s obj.name="Bob"
/// w obj.name
/// w obj.age
/// w obj.getAge()
/// w obj.getAgePlus(10)
Method %OnNew(type As %String = "", variable As %String, serialization As %Integer = {##class(isc.py.Callout).#SerializationStr}, args...) As %Status [ Private, ServerOnly = 1 ]
{
	set ..%Variable = variable
	set ..%Serialization = serialization
	
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
	
	$$$TOE(sc, ##class(isc.py.Main).SimpleString("zzzproperty=" _ ..%Variable _ "." _ property, "zzzproperty", ..%Serialization, .zzzproperty))
	$$$TOE(sc, ##class(isc.py.Main).SimpleString("del zzzproperty"))
	
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
	set arguments = $lb(..%Variable,##class(isc.py.util.Converter).EscapeString(property), value)
	
	$$$TOE(sc, ##class(isc.py.Main).ExecuteFunction("setattr", arguments))
}

/// Call python function
Method %DispatchMethod(method As %String, args...) [ ServerOnly = 1 ]
{
	$$$TOE(sc, ##class(isc.py.Main).ExecuteFunctionArgs(..%Variable _ "." _ method, ,..%Serialization, .result, args...))
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
Method %ToStream(serialization As %Integer = {..%Serialization}, ByRef stream As %Stream.Object, useString As %Boolean = {$$$NO}) As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).GetVariable(..%Variable, serialization, .stream, useString)
}

}

