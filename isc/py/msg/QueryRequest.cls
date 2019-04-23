/// Create pandas dataframe or list form sql.
Class isc.py.msg.QueryRequest Extends (Ens.Request, isc.py.msg.DataRequest)
{

/// Text of the SQL query
Property Query As %VarString;

Storage Default
{
<Data name="QueryRequestDefaultData">
<Subscript>"QueryRequest"</Subscript>
<Value name="1">
<Value>Query</Value>
</Value>
<Value name="2">
<Value>Variable</Value>
</Value>
<Value name="3">
<Value>Type</Value>
</Value>
<Value name="4">
<Value>Namespace</Value>
</Value>
</Data>
<DefaultData>QueryRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

