/// Restore saved Python context
Class isc.py.msg.RestoreRequest Extends Ens.Request
{

/// Context identifier to restore
Property ContextId As %Integer;

Storage Default
{
<Data name="RestoreRequestDefaultData">
<Subscript>"RestoreRequest"</Subscript>
<Value name="1">
<Value>ContextId</Value>
</Value>
</Data>
<DefaultData>RestoreRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

