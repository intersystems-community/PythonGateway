/// Transfer class data to python
Class isc.py.msg.ClassRequest Extends (Ens.Request, isc.py.msg.DataRequest)
{

/// Class name
Property Class As %Dictionary.CacheClassname [ Required ];

/// Initial object id
Property Start As %Integer [ InitialExpression = 1 ];

/// Final object id
Property End As %Integer;

/// Comma-separated list of properties to form dataframe from.
/// `*` and `?` wildcards are supported. 
/// Defaults to `*` (all properties). 
/// `%%CLASSNAME` property is ignored. 
/// Only stored properties can be used.
Property Properties As %VarString [ InitialExpression = "*" ];

Storage Default
{
<Data name="ClassRequestDefaultData">
<Subscript>"ClassRequest"</Subscript>
<Value name="1">
<Value>Class</Value>
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
<DefaultData>ClassRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

