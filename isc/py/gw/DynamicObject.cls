/// Dynamic Python object
Class isc.py.gw.DynamicObject Extends %RegisteredObject
{

Property %Name As %String(MAXLEN = 1000);

Property %Type As %String(MAXLEN = 1000);

Property %Serialization As %Integer;

/// do ##class(isc.py.init.Test).Initialize(,1)
/// set obj = ##class(isc.py.gw.DynamicObject).%New("Person", "p1", , "'Ed'", "25", "'Test'")
/// w obj.name
/// s obj.name="Bob"
/// w obj.name
/// w obj.age
/// w obj.getAge()
/// w obj.getAgePlus(10)
Method %OnNew(type, variable, serialization As %Integer = {##class(isc.py.Callout).#SerializationStr}, args...) As %Status [ Private, ServerOnly = 1 ]
{
	set ..%Name = variable
	set ..%Type = type 
	set ..%Serialization = serialization
	quit ##class(isc.py.Main).ExecuteFunctionArgs(type, variable,,, args...)
}

/// Get serialized property value
Method %DispatchGetProperty(property As %String) [ ServerOnly = 1 ]
{
	$$$TOE(sc, ##class(isc.py.Main).GetVariableInfo(..%Name _ "." _ property, ..%Serialization, .defined, .type, .length))
	throw:'defined ##class(%Exception.General).%New("<PROPERTY>", property)
	
	$$$TOE(sc, ##class(isc.py.Main).SimpleString("zzzproperty=" _ ..%Name _ "." _ property, "zzzproperty", ..%Serialization, .zzzproperty))
	$$$TOE(sc, ##class(isc.py.Main).SimpleString("del zzzproperty"))
	
	quit zzzproperty
}

/// Set python object property
Method %DispatchSetProperty(property As %String, val) [ ServerOnly = 1 ]
{
	$$$TOE(sc, ##class(isc.py.Main).GetVariableInfo(..%Name _ "." _ property, ..%Serialization, .defined, .type, .length))
	throw:'defined ##class(%Exception.General).%New("<PROPERTY>", property)
	
	set arguments = $lb(..%Name, ##class(isc.py.util.Converter).EscapeString(property), ##class(isc.py.util.Converter).EscapeString(val))
	
	$$$TOE(sc, ##class(isc.py.Main).ExecuteFunction("setattr", arguments))
}

/// Call python function
Method %DispatchMethod(method As %String, args...) [ ServerOnly = 1 ]
{
	$$$TOE(sc, ##class(isc.py.Main).ExecuteFunctionArgs(..%Name _ "." _ method, ,..%Serialization, .result, args...))
	quit result
}

}

