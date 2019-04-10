/// Python class property
Class isc.py.gw.PyString Extends %String
{

Parameter PyName;

Method Get() As %String [ CodeMode = objectgenerator, NoContext ]
{
	#; don't generate any code if it not for a property
	quit:%mode'="propertymethod" $$$OK
	set property = %parameter("PyName")
	set:property="" property = $g(%member)
	do %code.WriteLine($c(9) _ "quit ..%DispatchGetProperty(""" _ property _ """)")
	quit $$$OK
}

Method Set(%val) [ CodeMode = objectgenerator, NoContext ]
{
	quit:%mode'="propertymethod" $$$OK
	set property = %parameter("PyName")
	set:property="" property = $g(%member)
	do %code.WriteLine($c(9) _ "do ..%DispatchSetProperty(""" _ property _ """, %val)")
	quit $$$OK
}

}

