/// Request to python operation
Class isc.py.ens.Request Extends Ens.Request
{

/// Python code to execute
Property Code As %VarString;

/// Comma-separated list of variables to get in response message
Property Variables As %String;

/// Separate incoming message into lines for execution.
/// $c(10) is used for line separation
/// Note that it's NOT recommended to process whole message at once, 
/// this feature is only for `def` and similar multi-line expressions processing.
Property SeparateLines As %Boolean [ InitialExpression = {$$$YES} ];

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
<Value name="3">
<Value>LineSeparator</Value>
</Value>
<Value name="4">
<Value>SeparateLines</Value>
</Value>
</Data>
<DefaultData>RequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

