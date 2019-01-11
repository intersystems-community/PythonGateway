/// Stored Python variable
Class isc.py.data.Varable Extends %Persistent
{

/// Variable Name	
Property Name As %String;

/// Variable Class
Property Type As %String;

/// Variable repr
Property Value As %VarString;

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
	do ##class(isc.py.Callout).SimpleString("import json;")
	if type = "DataFrame" {
		//set json = ##class(isc.py.Callout).SimpleString("zzzjson=json.dumps([list("_name_".index), list("_name_"), "_name_".values.tolist()])", "zzzjson")
		set json = ##class(isc.py.Callout).SimpleString("zzzjson=" _name _ ".to_json()", "zzzjson")
		set repr =  ##class(isc.py.Callout).SimpleString("zzzjson=" _name _ ".to_dict()", "zzzjson")
	} else {
		set json = ##class(isc.py.Callout).SimpleString("zzzjson=json.dumps(" _name _ ")", "zzzjson")
	}
	
	
	do ##class(isc.py.Callout).SimpleString("del zzztype, zzzjson")

	set variable = ..%New()
	set variable.Name = name
	set variable.Value = repr
	set variable.Type = type
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
		Write indent, "Value (truncated): ", $e(..Value,1,limit), !
	}
	write !
}

/// Restore variable for disk.
Method Restore(context As isc.py.data.Context)
{
	if ..Type = "DataFrame" {
		set pandas = context.Modules.GetAt("pandas")
		do ##class(isc.py.Callout).SimpleString(..Name _ "=" _ pandas _".DataFrame.from_dict(" _ ..Value _ ")")
	} else {
		do ##class(isc.py.Callout).SimpleString(..Name _ "=" _ ..Value)
	}
}

Storage Default
{
<Data name="VarableDefaultData">
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
<Value>JSON</Value>
</Value>
</Data>
<DataLocation>^isc.py.data.VarableD</DataLocation>
<DefaultData>VarableDefaultData</DefaultData>
<IdLocation>^isc.py.data.VarableD</IdLocation>
<IndexLocation>^isc.py.data.VarableI</IndexLocation>
<StreamLocation>^isc.py.data.VarableS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

