/// Transfer Global Dat to Python
Class isc.py.msg.GlobalRequest Extends (Ens.Request, isc.py.msg.DataRequest)
{

/// global name without "^"
Property Global As %String [ Required ];

/// Initial global key.
Property Start As %Integer [ InitialExpression = 1 ];

/// Final global key.
Property End As %Integer;

/// Mask for global values. Mask may be shorter than the number of global value fields (in this case fields at the end would be skipped). 
/// How to format mask:
///  `+` use field as is
///  `-` skip field
///  `b` - boolean (0 - False, anything else - True)
///  `d` - date (from $horolog, on Windows only from 1970, on Linux from 1900 see notes for details)
///  `t` - time ($horolog, seconds since midnight) 
///  `m` - (moment) timestamp string in YEAR-MONTH-DAY HOUR:MINUTE:SECOND format.
Property Mask As %String;

/// - `labels` - %List of column names, first element is key column name. 
/// Therefore: List length must be mask symbol length + 1.
/// If comma-separated string is used it would be converted to %List automatically.
Property Labels As %List;

Method GlobalSet(value) As %Status
{
	set:$e(value)="^" value = $e(value, 2, *)
	set i%Global = value
	quit $$$OK
}

Method LabelsSet(value) As %Status
{
	set:'$lv(value) value = $lts(value)
	set i%Labels = value
	quit $$$OK
}

Storage Default
{
<Data name="GlobalRequestDefaultData">
<Subscript>"GlobalRequest"</Subscript>
<Value name="1">
<Value>Global</Value>
</Value>
<Value name="2">
<Value>Start</Value>
</Value>
<Value name="3">
<Value>End</Value>
</Value>
<Value name="4">
<Value>Mask</Value>
</Value>
<Value name="5">
<Value>Labels</Value>
</Value>
<Value name="6">
<Value>Namespace</Value>
</Value>
<Value name="7">
<Value>Type</Value>
</Value>
<Value name="8">
<Value>Variable</Value>
</Value>
</Data>
<DefaultData>GlobalRequestDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

