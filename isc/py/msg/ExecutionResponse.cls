/// Response from Python environment
Class isc.py.msg.ExecutionResponse Extends Ens.Response
{

/// Array of Python variables
Property Variables As array Of %VarString;

Storage Default
{
<Data name="Variables">
<Attribute>Variables</Attribute>
<Structure>subnode</Structure>
<Subscript>"isc.py.msg.ExecutionResponse.Variables"</Subscript>
</Data>
<Type>%Library.CacheStorage</Type>
}

}

