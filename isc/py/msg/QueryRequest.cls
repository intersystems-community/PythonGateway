/// Create pandas dataframe or list form sql.
Class isc.py.msg.QueryRequest Extends Ens.Request
{

/// Text of the SQL query
Property Query As %VarString;

/// Python variable to set
Property Variable As %String;

/// Variable type (Currently supported: dataframe (pandas dataframe) and list.
/// Pandas automatically imported if required.
Property Type As %String(VALUELIST = ",dataframe,list") [ InitialExpression = "list" ];

/// Namespace in which to execute the query
Property Namespace As %String [ InitialExpression = {$namespace} ];

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

