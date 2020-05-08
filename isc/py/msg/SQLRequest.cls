/// Execute SQL Query in the current process
Class isc.py.msg.SQLRequest Extends Ens.Request
{

/// Query to execute, in a form of
/// - SQL Query
/// - Class:Query
/// - Class:XData
Property Query As %VarString;

/// Query arguments, if any
Property Args As list Of %String;

Storage Default
{
<Data name="SQLRequestDefaultData">
<Subscript>"SQLRequest"</Subscript>
<Value name="1">
<Value>Query</Value>
</Value>
<Value name="2">
<Value>Args</Value>
</Value>
</Data>
<DefaultData>SQLRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

