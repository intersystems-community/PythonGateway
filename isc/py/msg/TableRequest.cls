/// Transfer table data to python
Class isc.py.msg.TableRequest Extends (Ens.Request, isc.py.msg.DataRequest)
{

/// Table name
Property Table As %String(MAXLEN = 500) [ Required ];

/// Initial row id
Property Start As %Integer [ InitialExpression = 1 ];

/// Final row id
Property End As %Integer;

/// Comma-separated list of class properties to form dataframe from.
/// `*` and `?` wildcards are supported. 
/// Defaults to `*` (all properties). 
/// `%%CLASSNAME` property is ignored. 
/// Only stored properties can be used.
Property Properties As %VarString [ InitialExpression = "*" ];

Storage Default
{
<Data name="TableRequestDefaultData">
<Subscript>"TableRequest"</Subscript>
<Value name="1">
<Value>Table</Value>
</Value>
<Value name="2">
<Value>Start</Value>
</Value>
<Value name="3">
<Value>End</Value>
</Value>
<Value name="4">
<Value>Properties</Value>
</Value>
<Value name="5">
<Value>Namespace</Value>
</Value>
<Value name="6">
<Value>Type</Value>
</Value>
<Value name="7">
<Value>Variable</Value>
</Value>
</Data>
<DefaultData>TableRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

