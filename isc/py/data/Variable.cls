/// Stored Python variable
Class isc.py.data.Variable Extends %Persistent
{

Parameter DisplayLimit = 100;

/// Variable Name	
Property Name As %String;

/// Variable Class
Property Type As %String;

/// Variable repr serialization
Property Value As %Stream.GlobalCharacter;

/// Variable pickle serialization
Property Pickle As %Stream.GlobalCharacter;

/// Variable JSON serialization
Property JSON As %Stream.GlobalCharacter;

/// Save variable on disk.
/// Do not save if length > maxLength
/// zw ##class(isc.py.data.Variable).SaveVariable()
ClassMethod SaveVariable(variable As %String = "", maxLength As %Integer = {$$$MaxStringLength}, Output obj As isc.py.data.Variable) As %Status
{
	#include Ensemble
	kill obj
	quit:variable="" $$$ERROR($$$GeneralError, "Variable name can't be empty")
	
	//$$$TRACE(variable)
	
	set sc = ##class(isc.py.Main).GetVariableInfo(variable, ##class(isc.py.Callout).#SerializationRepr, .defined, .type, .length)
	quit:(($$$ISERR(sc)) || ((maxLength>0) && (length>maxLength))) sc
	quit:'defined $$$ERROR($$$GeneralError, "Variable '" _ variable _ "' is not defined")	
	
	#dim repr, pickle, json As %Stream.GlobalCharacter
		
	set sc = ##class(isc.py.Main).GetVariable(variable, ##class(isc.py.Callout).#SerializationRepr, .repr)
	quit:$$$ISERR(sc) sc
	
	//  Ignore errors, as some types can't be serialized.
	set sc = ##class(isc.py.Main).GetVariableJson(variable, .json)	
	set sc = ##class(isc.py.Main).GetVariablePickle(variable, .pickle)

	set obj = ..%New()
	set obj.Name = variable
	set obj.Value = repr
	set obj.Type = type
	set obj.Pickle = pickle
	set obj.JSON = json
	set sc = obj.%Save()

	quit sc
}

/// Get saved JSON stream as dynamic object.
/// set sc = ##class(isc.py.data.Variable).AsDynamicObject(,.obj)
ClassMethod AsDynamicObject(id As %Integer = "", Output dynObj) As %Status
{
	kill dynObj
	quit:'..%ExistsId(id) $$$ERROR($$$LoadObjectNotFound, $classname(), id)  
	set stream = ##class(%Stream.GlobalCharacter).%Open($listbuild(..JSONGetStored(id), "%Stream.GlobalCharacter", "^isc.py.data.VariableS"),,.sc)
	
	try {
		set dynObj = {}.%FromJSON(stream)
	} catch ex {
		set sc = ex.AsStatus()
	}
	quit sc
}

/// Dispaly variable on the current device.
Method Display(indent As %String = "")
{
	write indent, "Name: ", ..Name, !
	write indent, "Type: ", ..Type, !	
	write indent, "Value", $case(..Value.Size<=..#DisplayLimit, $$$YES:"", $$$NO:" (truncated)"), ": ", ..Value.Read(..#DisplayLimit), !, !
}

/// Restore variable from disk.
/// context - variable owner Python context object.
Method Restore(context As isc.py.data.Context) As %Status
{
	#dim sc As %Status = $$$OK
	if ..Pickle.Size > 0 {
		set stream = ##class(%Stream.TmpCharacter).%New()
		do stream.Write(context.%PickleAlias _ ".loads(")
		do stream.CopyFrom(..Pickle)
		do stream.Write(")")
		set sc = ##class(isc.py.Main).ExecuteCode(stream, ..Name)
	}
	
	quit sc
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

