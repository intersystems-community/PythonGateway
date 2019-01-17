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

Parameter StreamInit As Integer = 7;

Parameter StreamWrite As Integer = 8;

Parameter StreamExecute As Integer = 9;

/// Get path to the shared library file. 
/// Library file is assumed to be in a bin folder, unless specified otherwise in ^isc.py.Callout global.
/// write ##class(isc.py.Callout).GetLib()
ClassMethod GetLib() [ CodeMode = expression ]
{
$g(^isc.py.Callout, $g(^%SYS("bindir")) _ "iscpython." _ $select($$$isWINDOWS:"dll", 1:"so"))
}

/// Should be executed once per system start. Idempotent.
/// Add to ZSTART or production start.
/// write ##class(isc.py.Callout).Setup()
ClassMethod Setup()
{
	set sc = $ZF(-4,6,..#PyLibId)
    set sc = $ZF(-4,5,..#PyLibId, ..GetLib())
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
		set sc = $ZF(-4,7,..#PyLibId, ..GetLib())  	// override system index
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
	set:$ZISWIDE(code) code = $zcvt(code, "O", "UTF8")

	set result = $ZF(-6, ..#PyLibId, ..#SimpleStringFull, code)
	set result = $zcvt(result, "I", "UTF8")
	quit result
}

/// Eval code vaiable in initialized context and 
/// return value of variable str evaluation
/// serialization - currenlty: 0 - string serialization, 1 - repr serialization.
/// TODO determine wide variable value.
/// write ##class(isc.py.Callout).SimpleString()
ClassMethod SimpleString(code As %String = "", variable As %String = "", serialization As %Integer = 0) As %String
{
	set:$ZISWIDE(code) code = $zcvt(code, "O", "UTF8")
	set result = $ZF(-6, ..#PyLibId, ..#SimpleString, code, variable, serialization)
	
	// Slows getting result by ~50%
	set result = $zcvt(result, "I", "UTF8")
	quit result
}

/// Init incoming Stream
/// write ##class(isc.py.Callout).StreamInit()
ClassMethod StreamInit(length As %Integer) As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#PyLibId, ..#StreamInit, length)
	} catch ex {
		#dim ex As %Exception.General
		if (ex.Name = "<FUNCTION>") {
			set sc = $$$ERROR($$$GeneralError, "Unable to allocate memory")
		} else {
			set sc = ex.AsStatus()
		}
	}
	
	quit sc
}

/// Write piece into incoming Stream
/// write ##class(isc.py.Callout).StreamWrite()
ClassMethod StreamWrite(code As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#PyLibId, ..#StreamWrite, code)
	} catch ex {
		#dim ex As %Exception.General
		if (ex.Name = "<FUNCTION>") {
			set sc = $$$ERROR($$$GeneralError, "Call StreamInit before calling StreamWrite. Or attempted to write into stream more than allocated data.")
		} else {
			set sc = ex.AsStatus()
		}
	}
	
	quit sc
}

/// Send incoming stream to Python for execution and free it.
/// write ##class(isc.py.Callout).StreamExecute()
ClassMethod StreamExecute() As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#PyLibId, ..#StreamExecute)
	} catch ex {
		#dim ex As %Exception.General
		if (ex.Name = "<FUNCTION>") {
			set sc = $$$ERROR($$$GeneralError, "Call StreamInit and StreamWrite before calling StreamExecute")
		} else {
			set sc = ex.AsStatus()
		}
	}
	
	quit sc
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

