/// Response from Python environment
Class isc.py.msg.StreamExecutionResponse Extends Ens.Response
{

/// Array of Python variables
Property Variables As array Of %Stream.GlobalCharacter(XMLPROJECTION = "NONE");

Storage Default
{
<Data name="Variables">
<Attribute>Variables</Attribute>
<Structure>subnode</Structure>
<Subscript>"isc.py.msg.StreamExecutionResponse.Variables"</Subscript>
</Data>
<Type>%Library.CacheStorage</Type>
}

}

