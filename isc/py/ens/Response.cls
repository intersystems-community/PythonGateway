/// Response from Python environment
Class isc.py.ens.Response Extends Ens.Response
{

/// Array of Python variables
Property Variables As array Of %VarString;

Storage Default
{
<Data name="Variables">
<Attribute>Variables</Attribute>
<Structure>subnode</Structure>
<Subscript>"isc.py.ens.Response.Variables"</Subscript>
</Data>
<Type>%Library.CacheStorage</Type>
}

}

