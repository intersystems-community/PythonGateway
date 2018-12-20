/// Main callout wrapper. 
/// To use:
/// 1. Call: do ##class(isc.py.Callout).Setup() once per systems start
/// 2. Call: do ##class(isc.py.Callout).Initialize() once per process
/// 3. Call main method (can be called many times, context persists): write ##class(isc.py.Callout).SimpleString(code, data)
/// 4. Call: do ##class(isc.py.Callout).Finalize() to free Python context
/// 5. Call: write ##class(isc.py.Callout).Unload() to free callout library
Class isc.py.Callout
{

Parameter PyLibId As Integer = 4937;

Parameter Initialize As Integer = 1;

Parameter Finalize As Integer = 2;

Parameter GetRandom As Integer = 3;

Parameter GetRandomSimple As Integer = 4;

Parameter SimpleStringFull As Integer = 5;

Parameter SimpleString As Integer = 6;

Parameter DLL As COSEXPRESSION = "$g(^isc.py.Callout, $g(^%SYS(""bindir"")) _ ""iscpython.dll"")";

/// Should be executed once per system start. Idempotent.
/// Add to ZSTART or production start.
/// write ##class(isc.py.Callout).Setup()
ClassMethod Setup()
{
	set sc = $ZF(-4,6,..#PyLibId)
    set sc = $ZF(-4,5,..#PyLibId, ..#DLL)
    quit sc
}

/// Init Python context. Idempotent.
/// do ##class(isc.py.Callout).Initialize()
ClassMethod Initialize(debug As %Boolean = {$$$NO}) As %Integer
{
	if debug {
		set sc = $ZF(-4,4,..#PyLibId)   		// unload current copy of inputlib
		set sc = $ZF(-4,8)   					// delete existing process index, if any
		set sc = $ZF(-4,7,..#PyLibId, ..#DLL)  	// override system index
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
	set path = ..#DLL
	set result = $ZF(-6, ..#PyLibId, ..#SimpleStringFull, code)
	set:converted result = $zcvt(result, "I", "UTF8")
	quit result
}

/// Eval code vaiable in initialized context and 
/// return value of variable str evaluation
/// write ##class(isc.py.Callout).SimpleString()
ClassMethod SimpleString(code As %String = {"import random;" _ $$$NL _ "x=random.random();"}, variable As %String = "x") As %Double
{
	set converted = $$$NO
	if $ZISWIDE(code) {
		set code = $zcvt(code, "O", "UTF8")
		set converted = $$$YES
	}
	set path = ..#DLL
	set result = $ZF(-6, ..#PyLibId, ..#SimpleString, code, variable)
	
	set:converted result = $zcvt(result, "I", "UTF8")
	quit result
}

/// Finalize Python. Idempotent.
/// do ##class(isc.py.Callout).Finalize()
ClassMethod Finalize() As %Integer
{
	set path = ..#DLL
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

