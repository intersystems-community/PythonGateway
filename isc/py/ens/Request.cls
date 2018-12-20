/// Request to python operation
Class isc.py.ens.Request Extends Ens.Request
{

/// Python code to execute
Property Code As %VarString;

/// Comma-separated list of variables to get in response message
Property Variables As %String;

Storage Default
{
<Data name="RequestDefaultData">
<Subscript>"Request"</Subscript>
<Value name="1">
<Value>Code</Value>
</Value>
<Value name="2">
<Value>Variables</Value>
</Value>
</Data>
<DefaultData>RequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

