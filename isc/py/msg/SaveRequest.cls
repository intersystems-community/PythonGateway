/// Save Python context to disk.
Class isc.py.msg.SaveRequest Extends Ens.Request
{

/// Comma-separated list of variables to save.
/// Only variables that satisfy Mask are saved.
/// Wildcards * and ? are accepted.
/// Example: "Data*,Figure?"
Property Mask As %VarString [ InitialExpression = "*" ];

/// Maximum length of saved variable. 
/// If veriable serialization is longer than that, it would be ignored. 
/// Set to 0 to get them all.
Property MaxLength As %Integer [ InitialExpression = {$$$MaxStringLength} ];

/// Short name for the context.
Property Name As %String;

/// Extended context info.
Property Description As %VarString;

Storage Default
{
<Data name="SaveRequestDefaultData">
<Subscript>"SaveRequest"</Subscript>
<Value name="1">
<Value>Mask</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>MaxLength</Value>
</Value>
</Data>
<DefaultData>SaveRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

