Class isc.py.data.Function Extends %Persistent
{

/// Function Name	
Property Name As %String(MAXLEN = 100);

/// dill serialization
Property Dill As %Stream.GlobalCharacter;

/// Function documentation
Property Docs As %VarString;

/// Function signature
Property Signature As %VarString;

/// JSON representation of Signature
/// str is 'FullArgSpec(args=[\\'a\\', \\'b\\'], varargs=None, varkw=None, defaults=None, kwonlyargs=[\\'c\\', \\'d\\'], kwonlydefaults={\\'d\\': 10}, annotations={})'
/// json is [args, varargs, varkw, kwonlyargs, kwonlydefaults, annotations]
Property Arguments As %VarString;

ClassMethod SaveFunction(function As %String = "", Output obj As isc.py.data.Function) As %Status
{
	kill obj
	quit:function="" $$$ERROR($$$GeneralError, "Variable name can't be empty")
	
	set sc = ##class(isc.py.Main).GetFunctionInfo(function, .defined, .docs, .signature, .arguments)
	quit:$$$ISERR(sc) sc
	
	set sc = ##class(isc.py.Main).GetVariablePickle(function ,.dill,, $$$YES)
	
	set obj = ..%New()
	set obj.Name = function
	set obj.Docs = docs
	set obj.Signature = signature
	set obj.Arguments = arguments
	set obj.Dill = dill
	
	
	quit obj.%Save()
}

/// Restore variable from disk.
/// context - variable owner Python context object.
Method Restore(context As isc.py.data.Context) As %Status
{
	#dim sc As %Status = $$$OK
	if ..Dill.Size > 0 {
		set stream = ##class(%Stream.TmpCharacter).%New()		
		do stream.Write(context.%DillAlias _ ".loads(")
		do stream.CopyFrom(..Dill)
		do stream.Write(")")
		set sc = ##class(isc.py.Main).ExecuteCode(stream, ..Name)
	}
	
	quit sc
}

/// Dispaly function on the current device.
Method Display(indent As %String = "")
{
	write indent, ..Name, ..Signature, $case(..Docs'="", $$$YES: " - " _ ..Docs, :""), !
}

Storage Default
{
<Data name="FunctionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Dill</Value>
</Value>
<Value name="4">
<Value>Docs</Value>
</Value>
<Value name="5">
<Value>Signature</Value>
</Value>
<Value name="6">
<Value>Arguments</Value>
</Value>
</Data>
<DataLocation>^isc.py.data.FunctionD</DataLocation>
<DefaultData>FunctionDefaultData</DefaultData>
<IdLocation>^isc.py.data.FunctionD</IdLocation>
<IndexLocation>^isc.py.data.FunctionI</IndexLocation>
<StreamLocation>^isc.py.data.FunctionS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

