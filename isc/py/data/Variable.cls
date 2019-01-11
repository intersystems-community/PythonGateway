/// Stored Python variable
Class isc.py.data.Variable Extends %Persistent
{

/// Variable Name	
Property Name As %String;

/// Variable Class
Property Type As %String;

/// Variable repr serialization
Property Value As %VarString;

/// Variable pickle serialization
Property Pickle As %VarString;

/// Variable JSON serialization
Property JSON As %VarString;

/// Save variable on disk.
/// zw ##class(isc.py.data.Varable).SaveVariable()
ClassMethod SaveVariable(name As %String = "", Output variable As isc.py.data.Varable) As %Status
{
	kill variable
	quit:name="" $$$ERROR($$$GeneralError, "Variable name can't be empty")
	
	set repr = ##class(isc.py.Callout).SimpleString(,name, 1)
	quit:repr="" $$$ERROR($$$GeneralError, $$$FormatText("Variable %1 is empty or initialized", name))
	
	set type = ##class(isc.py.Callout).SimpleString("zzztype=type("_name_").__name__", "zzztype")
	do ##class(isc.py.Callout).SimpleString("import json, pickle;")
	
	if type = "DataFrame" {
		set json = ##class(isc.py.Callout).SimpleString("zzzjson=" _name _ ".to_json()", "zzzjson")
	} else {
		set json = ##class(isc.py.Callout).SimpleString("zzzjson=json.dumps(" _name _ ")", "zzzjson")
	}
	
	set pickle = ##class(isc.py.Callout).SimpleString("zzzjson=pickle.dumps(" _name _ ")", "zzzjson")
	
	
	do ##class(isc.py.Callout).SimpleString("del zzztype, zzzjson")

	set variable = ..%New()
	set variable.Name = name
	set variable.Value = repr
	set variable.Type = type
	set variable.Pickle = pickle
	set variable.JSON = json
	set sc = variable.%Save()

	quit sc
}

/// Dispaly variable on the current device.
Method Display(indent As %String = "")
{
	write indent, "Name: ", ..Name, !
	write indent, "Type: ", ..Type, !
	set limit = 100
	If $l(..Value)<=limit {
		Write indent, "Value: ", ..Value, !
	} Else {
		Write indent, "Value (truncated): ", $replace($e(..Value,1,limit),$c(10), $c(13,10)), !
	}
	write !
}

/// Restore variable for disk.
Method Restore(context As isc.py.data.Context)
{
	do ##class(isc.py.Callout).SimpleString(..Name _ "=pickle.loads(" _ ..Pickle _ ")")
}

Storage Default
{
<Data name="VariableDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Type</Value>
</Value>
<Value name="4">
<Value>Value</Value>
</Value>
<Value name="5">
<Value>Pickle</Value>
</Value>
<Value name="6">
<Value>JSON</Value>
</Value>
</Data>
<DataLocation>^isc.py.data.VariableD</DataLocation>
<DefaultData>VariableDefaultData</DefaultData>
<IdLocation>^isc.py.data.VariableD</IdLocation>
<IndexLocation>^isc.py.data.VariableI</IndexLocation>
<StreamLocation>^isc.py.data.VariableS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

