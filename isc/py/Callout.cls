/// Raw callout wrapper. Use isc.py.Main
/// To use:
/// 1. Call: do ##class(isc.py.Callout).Setup() once per systems start
/// 2. Call main method (can be called many times, context persists): write ##class(isc.py.Callout).SimpleString(code, variable)
/// 3. Call: do ##class(isc.py.Callout).Finalize() to clear Python context
/// 4. Call: write ##class(isc.py.Callout).Unload() to free callout library
Class isc.py.Callout
{

/// Serialization by str() function
Parameter SerializationStr = 0;

/// Serialization by repr() function
Parameter SerializationRepr = 1;

Parameter PyLibId As Integer = 4937;

Parameter Initialize As Integer = 1;

Parameter Finalize As Integer = 2;

Parameter SimpleString As Integer = 3;

Parameter StreamInit As Integer = 4;

Parameter StreamWrite As Integer = 5;

Parameter StreamExecute As Integer = 6;

Parameter EscapeString As Integer = 7;

Parameter GetGlobalOrder As Integer = 8;

/// Get path to the shared library file. 
/// Library file is assumed to be in a bin folder, unless specified otherwise in ^isc.py.Callout global.
/// write ##class(isc.py.Callout).GetLib()
ClassMethod GetLib() [ CodeMode = expression ]
{
$g(^isc.py.Callout, $g(^%SYS("bindir")) _ "iscpython." _ $select($$$isWINDOWS:"dll", $$$isMACOSX:"dylib", 1:"so"))
}

/// Should be executed once per system start. Idempotent.
/// Add to ZSTART or production start.
/// write ##class(isc.py.Callout).Setup()
ClassMethod Setup() As %Status
{
	#dim sc As %Status = $$$OK
	set file = ..GetLib()
	quit:'##class(%File).Exists(file) $$$ERROR($$$GeneralError, "Library file: " _ file _ " does not exist")	

	try {
		set result = $ZF(-4,6,..#PyLibId)
		if result'=0 {
			set sc = $$$ERROR($$$GeneralError, "Failed $ZF(-4, 6,..#PyLibId) call with result: " _ result _ " expected 0")
			quit
		}
		
		set result =$ZF(-4,5,..#PyLibId, file)
		if result'=0 {
			set sc = $$$ERROR($$$GeneralError, "Failed $ZF(-4, 5,..GetLib()) call with result: " _ result _ " expected 0")
			quit
		}
	} catch ex {
		set sc = ex.AsStatus()
	}
	
	
    quit sc
}

/// Initializes Python environment. Idempotent.
/// Currently this is done automatically on a C side of things.
/// file - path to a Python shared library. (Linux only, optional)
/// Due to the problems with lib-dynload, sometimes library file should be loaded explicitly on Linux
/// For more info see: https://bugs.python.org/issue4434
/// Do not use it, unless you get errors like: undefined symbol: _Py_TrueStruct and so on
/// do ##class(isc.py.Callout).Initialize()
/// In cause of problems: do ##class(isc.py.Callout).Initialize("libpython3.6m.so") 
ClassMethod Initialize(file As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#PyLibId, ..#Initialize, file)
	} catch ex {
		set sc = ex.AsStatus()
	}
	quit sc
}

/// Eval code vaiable in initialized context and 
/// return value of variable str evaluation
/// serialization - currenlty: 0 - string serialization, 1 - repr serialization.
/// TODO determine wide variable value.
/// write ##class(isc.py.Callout).SimpleString()
ClassMethod SimpleString(code As %String = "", variable As %String = "", serialization As %Integer = {..#SerializationStr}) As %String
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

/// Write piece into incoming Stream.
/// If initial length is not enough, additional allocation is performed.
/// write ##class(isc.py.Callout).StreamWrite()
ClassMethod StreamWrite(code As %String = "") As %Status
{
	#dim sc As %Status = $$$OK
	try {
		set:$ZISWIDE(code) code = $zcvt(code, "O", "UTF8")
		do $ZF(-6, ..#PyLibId, ..#StreamWrite, code)
	} catch ex {
		#dim ex As %Exception.General
		if (ex.Name = "<FUNCTION>") {
			set sc = $$$ERROR($$$GeneralError, "Call StreamInit before calling StreamWrite. Or reallocation failed as initial allocation in StreamInit could not hold all the data.")
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

/// Write piece into incoming Stream.
/// If initial length is not enough, additional allocation is performed.
/// write ##class(isc.py.Callout).EscapeString()
ClassMethod EscapeString(string As %String = "") As %String
{
	set:$ZISWIDE(string) string = $zcvt(string, "O", "UTF8")
	set result = $ZF(-6, ..#PyLibId, ..#EscapeString, string)
	
	// Slows getting result by ~50%
	set result = $zcvt(result, "I", "UTF8")
	quit result
}

/// Finalize Python. Idempotent.
/// write ##class(isc.py.Callout).Finalize()
ClassMethod Finalize() As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#PyLibId, ..#Finalize)
	} catch ex {
		#dim ex As %Exception.General
		set sc = ex.AsStatus()
	}
	quit sc
}

/// Transfer global to Python list of tuples
/// global - name of global
/// start - starting global key
/// end - final global key
/// mask - mask for $lb fields
/// name - list name
/// How to format mask:
/// + as is
/// - skip
/// b - boolean
/// d - date
/// t - time
/// 
/// s ^BDZ4.DfXU.1(2)=$lb(1,64756,"4post21","@elina_4post как говорят обещаного три года ждут...((",2.1,-2.1,-4096,-65536,718,49,249,0)
/// s ^BDZ4.DfXU.1(1)=$lb(0,48000,"nugemycejela","Коллеги сидят рубятся в Urban terror, а я из-за долбанной винды не могу :(",-1,-256,256.2,0,26,42,39,0)
/// write ##class(isc.py.Callout).GetGlobalOrder("a",1,2,"+",,1)
/// write ##class(isc.py.Callout).GetGlobalOrder("isc.py.test.PersonD",1,5,"++++++++")
/// write ##class(isc.py.Callout).GetGlobalOrder("BDZ4.DfXU.1",1,2,      "bd++++++++++")
/// write ##class(isc.py.Callout).GetGlobalOrder("BDZ4.DfXU.1",1,111922, "++++++++++++")
ClassMethod GetGlobalOrder(global, start As %Integer, end As %Integer, mask As %String, name As %String = "l", unload As %Boolean = 0) As %Status
{
	#dim sc As %Status = $$$OK
	try {
		do $ZF(-6, ..#PyLibId, ..#GetGlobalOrder, global, start, end, mask, name)
	} catch ex {
		#dim ex As %Exception.General
		set sc = ex.AsStatus()
	}
	do:unload ..Unload()
	quit sc
}

/// Unload library. Idempotent.
/// write ##class(isc.py.Callout).Unload()
ClassMethod Unload() As %Status
{
	#dim sc As %Status = $$$OK
	
	try {
		set result = $ZF(-4, 4, ..#PyLibId)
		set:result'=0 sc = $$$ERROR($$$GeneralError, "Failed $ZF(-4, 4,..#PyLibId) call with result: " _ result _ " expected 0")
	} catch ex {
		set sc = ex.AsStatus()
	}

	quit sc
}

}

