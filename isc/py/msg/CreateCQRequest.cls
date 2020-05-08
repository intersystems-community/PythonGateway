/// Generate Custom Query based on a Python DataFrame
Class isc.py.msg.CreateCQRequest Extends Ens.Request
{

/// Python variable with DataFrame
Property Variable As %String [ Required ];

/// Classname to generate.
/// Overrides if exists.
Property Classname As %Dictionary.CacheClassname [ Required ];

}

