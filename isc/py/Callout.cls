/// Main callout wrapper. 
/// To use:
/// 1. Call: do ##class(isc.py.Callout).Setup() once per systems start
/// 2. Call main method (can be called many times, context persists): write ##class(isc.py.Callout).SimpleString(code, data)
/// 3. Call: do ##class(isc.py.Callout).Finalize() to clear Python context
/// 4. Call: write ##class(isc.py.Callout).Unload() to free callout library
Class isc.py.Callout
{

Parameter PyLibId As Integer = 4937;

Parameter Initialize As Integer = 1;

Parameter Finalize As Integer = 2;

Parameter GetRandom As Integer = 3;

Parameter GetRandomSimple As Integer = 4;

Parameter SimpleStringFull As Integer = 5;

Parameter SimpleString As Integer = 6;

/// Get path to DLL. 
/// DLL assumed to be in bin folder, unless specified otherwise
ClassMethod GetDLL() [ CodeMode = expression ]
{
$g(^isc.py.Callout, $g(^%SYS("bindir")) _ "iscpython." _ $select($$$isWINDOWS:"dll", 1:"so"))
}

/// Should be executed once per system start. Idempotent.
/// Add to ZSTART or production start.
/// write ##class(isc.py.Callout).Setup()
ClassMethod Setup()
{
	set sc = $ZF(-4,6,..#PyLibId)
    set sc = $ZF(-4,5,..#PyLibId, ..GetDLL())
    quit sc
}

/// Init Python context. Idempotent.
/// Currently this is done automatically on a C side of things.
/// Left for debugging/dev purposes.
/// do ##class(isc.py.Callout).Initialize()
ClassMethod Initialize(debug As %Boolean = {$$$NO}) As %Integer
{
	if debug {
		set sc = $ZF(-4,4,..#PyLibId)   			// unload current copy of inputlib
		set sc = $ZF(-4,8)   						// delete existing process index, if any
		set sc = $ZF(-4,7,..#PyLibId, ..GetDLL())  	// override system index
	}
	do $ZF(-6, ..#PyLibId, ..#Initialize)
}

/// Test method. Get random number
/// w ##class(isc.py.Callout).GetRandom()
ClassMethod GetRandom() As %Double
{
	set random = $ZF(-6, ..#PyLibId, ..#GetRandom)
	quit random
}

/// Test method. Get random number
/// w ##class(isc.py.Callout).GetRandomSimple()
ClassMethod GetRandomSimple() As %Double
{
	set random = $ZF(-6, ..#PyLibId, ..#GetRandomSimple)
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
	set result = $ZF(-6, ..#PyLibId, ..#SimpleStringFull, code)
	set:converted result = $zcvt(result, "I", "UTF8")
	quit result
}

/// Eval code vaiable in initialized context and 
/// return value of variable str evaluation
/// TODO determine wide variable value.
/// write ##class(isc.py.Callout).SimpleString()
ClassMethod SimpleString(code As %String = {"import random;" _ $$$NL _ "x=random.random();"}, variable As %String = "x") As %Double
{
	set converted = $$$NO
	if $ZISWIDE(code) {
		set code = $zcvt(code, "O", "UTF8")
		set converted = $$$YES
	}
	set result = $ZF(-6, ..#PyLibId, ..#SimpleString, code, variable)
	
	set:converted result = $zcvt(result, "I", "UTF8")
	quit result
}

/// Finalize Python. Idempotent.
/// do ##class(isc.py.Callout).Finalize()
ClassMethod Finalize() As %Integer
{
	do $ZF(-6, ..#PyLibId, ..#Finalize)
}

/// Unload library. Idempotent.
/// write ##class(isc.py.Callout).Unload()
ClassMethod Unload() As %Integer
{
	set result = $ZF(-4, 4, ..#PyLibId)
	quit result
}

}

