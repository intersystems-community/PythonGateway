Class isc.py.Callout
{

Parameter DLL As COSEXPRESSION = "$g(^isc.py.Callout, $g(^%SYS(""bindir"")) _ ""libhelloworld.dll"")";

/// Init Python context
/// do ##class(isc.py.Callout).Initialize()
ClassMethod Initialize() As %Integer
{
	set path = ..#DLL
	do $ZF(-3, path, "Initialize")
}

/// Test method. Get random number
/// w ##class(isc.py.Callout).GetRandom()
ClassMethod GetRandom() As %Double
{
	set path = ..#DLL
	set random = $ZF(-3, path, "GetRandom")
	quit random
}

/// Test method. Get random number
/// w ##class(isc.py.Callout).GetRandomSimple()
ClassMethod GetRandomSimple() As %Double
{
	set path = ..#DLL
	set random = $ZF(-3, path, "GetRandomSimple")
	quit random
}

/// Init, eval code and return variable x.
/// w ##class(isc.py.Callout).SimpleStringFull()
ClassMethod SimpleStringFull(code = {"import random;" _ $$$NL _ "x=random.random();"}) As %Double
{
	set converted = $$$NO
	if $ZISWIDE(code) {
		set code = $zcvt(code, "O", "UTF8")
		set converted = $$$YES
	}
	set path = ..#DLL
	set result = $ZF(-3, path, "SimpleStringFull", code)
	set:converted result = $zcvt(result, "I", "UTF8")
	quit result
}

/// Eval code vaiable in initialized context and 
/// return value of variable str evaluation
/// w ##class(isc.py.Callout).SimpleString()
ClassMethod SimpleString(code As %String = {"import random;" _ $$$NL _ "x=random.random();"}, variable As %String = "x") As %Double
{
	set converted = $$$NO
	if $ZISWIDE(code) {
		set code = $zcvt(code, "O", "UTF8")
		set converted = $$$YES
	}
	set path = ..#DLL
	set result = $ZF(-3, path, "SimpleString", code, variable)
	
	set:converted result = $zcvt(result, "I", "UTF8")
	quit result
}

/// Finalize Python 
/// do ##class(isc.py.Callout).Finalize()
ClassMethod Finalize() As %Integer
{
	set path = ..#DLL
	do $ZF(-3, path, "Finalize")
}

/// Unload library
/// write ##class(isc.py.Callout).Unload()
ClassMethod Unload() As %Integer
{
	set result = $ZF(-3, "")
	quit result
}

}

