Class isc.py.Callout
{

Parameter DLL As COSEXPRESSION = "$g(^isc.py.Callout)";

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

/// Init, eval code and return variable x.
/// w ##class(isc.py.Callout).SimpleString()
ClassMethod SimpleString(code = {"import random;" _ $$$NL _ "x=random.random();"}) As %Double
{
	set path = ..#DLL
	set result = $ZF(-3, path, "SimpleString", code)
	quit result
}

/// Eval code vaiable in initialized context and 
/// return value of variable (currently limited to double and similar)
/// w ##class(isc.py.Callout).SimpleStringN()
ClassMethod SimpleStringN(code As %String = {"import random;" _ $$$NL _ "x=random.random();"}, variable As %String = "") As %Double
{
	set path = ..#DLL
	set result = $ZF(-3, path, "SimpleStringN", code, variable)
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
/// write ##class(Utils.Callout).Unload()
ClassMethod Unload() As %Integer
{
	set result = $ZF(-3, "")
	quit result
}

}

