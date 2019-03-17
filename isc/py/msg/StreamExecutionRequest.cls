/// Same as ExecutionRequest but Code is a stream
Class isc.py.msg.StreamExecutionRequest Extends Ens.Request
{

/// Python code to execute
Property Code As %Stream.GlobalCharacter;

/// Comma-separated list of variables to get in response message
Property Variables As %String;

/// Separate incoming message into lines for execution.
/// $c(10) is used for line separation
/// Note that it's NOT recommended to process whole message at once, 
/// this feature is only for `def` and similar multi-line expressions processing.
Property SeparateLines As %Boolean [ InitialExpression = {$$$YES} ];

/// How to serialize variables we want to return
Property Serialization As %String(VALUELIST = ",Str,Repr,JSON,Pickle,Dill") [ InitialExpression = "Str" ];

Storage Default
{
<Data name="StreamExecutionRequestDefaultData">
<Subscript>"StreamExecutionRequest"</Subscript>
<Value name="1">
<Value>Code</Value>
</Value>
<Value name="2">
<Value>Variables</Value>
</Value>
<Value name="3">
<Value>SeparateLines</Value>
</Value>
<Value name="4">
<Value>Serialization</Value>
</Value>
</Data>
<DefaultData>StreamExecutionRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

