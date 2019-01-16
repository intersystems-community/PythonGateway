/// Save Python context to disk.
Class isc.py.msg.SaveRequest Extends Ens.Request
{

/// TODO Only variables that satisfy Mask are saved.
/// Wildcards * and ? are accepted, masks are commaseparated.
Property Mask As %VarString [ InitialExpression = "*" ];

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
</Data>
<DefaultData>SaveRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

