/// Create pandas dataframe or list form sql.
Class isc.py.msg.QueryRequest Extends Ens.Request
{

Property Query As %VarString;

Property Variable As %String;

Property Type As %String(VALUELIST = ",dataframe,list") [ InitialExpression = "list" ];

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
</Data>
<DefaultData>QueryRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

