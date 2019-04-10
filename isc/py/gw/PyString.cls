/// Python object property
Class isc.py.gw.PyString Extends %String
{

/// Specified in cases where property name on InterSystems IRIS side is not equal to Python attribute name 
Parameter PyName;

/// Generate Getter
Method Get() As %String [ CodeMode = objectgenerator, NoContext ]
{
	#; don't generate any code if it not for a property
	quit:%mode'="propertymethod" $$$OK
	set property = %parameter("PyName")
	set:property="" property = $g(%member)
	do %code.WriteLine($c(9) _ "quit ..%DispatchGetProperty(""" _ property _ """)")
	quit $$$OK
}

/// Generate Setter
Method Set(%val) [ CodeMode = objectgenerator, NoContext ]
{
	quit:%mode'="propertymethod" $$$OK
	set property = %parameter("PyName")
	set:property="" property = $g(%member)
	do %code.WriteLine($c(9) _ "do ..%DispatchSetProperty(""" _ property _ """, %val)")
	quit $$$OK
}

}

