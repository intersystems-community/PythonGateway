Class isc.py.ens.OutboundAdapter Extends Ens.OutboundAdapter
{

/// Linux only. Path (or just the filename) to python shared lib 
/// Due to the problems with lib-dynload, sometimes library file should be loaded explicitly on Linux
/// For more info see: https://bugs.python.org/issue4434
/// Do not use it, unless you get errors like: undefined symbol: _Py_TrueStruct and similar
/// In cause of problems set to: "libpython3.6m.so"
Property PythonLib As %String(MAXLEN = 1000);

Parameter SETTINGS = "PythonLib:Basic";

Method OnInit() As %Status
{
	do:..PythonLib'="" ##class(isc.py.Callout).Initialize(..PythonLib)
	quit $$$OK
}

/// Free Python library
Method OnTearDown() As %Status
{
	do ##class(isc.py.Callout).Finalize()
	do ##class(isc.py.Callout).Unload()
	quit $$$OK
}

/// Main method execute code and return variable.
/// All arguments are optional.
/// code - Python code to execute
/// variable - variable name, which value is returned
/// lineSeparator - separate code into lines. Defaults to $c(10).
Method Execute(code = "", variable = "", lineSeparator As %String = {$c(10)}, Output sc As %Status) As %String
{
	set sc = $$$OK
	if lineSeparator'="" {
		set codeList=$lfs(code, lineSeparator)
	} else {
		set codeList=$lb(code)
	}
	
	for i=1:1:$ll(codeList) {
		set line = $lg(codeList, i)
		$$$TRACE(line)	
		set sc = ##class(isc.py.Main).SimpleString(line)
		if $$$ISERR(sc) {
			set sc = $$$ADDSC($$$ERROR($$$GeneralError, "Code: " _ line), sc)
			/// TODO continue despite error?
			quit
		}
	}
	quit:$$$ISERR(sc) ""
	$$$TRACE("Var: " _ variable)
	set:variable'="" sc = ##class(isc.py.Main).GetVariable(variable, ##class(isc.py.Callout).#SerializationStr, .result, $$$YES)
	quit $g(result)
}

/// Main method execute stream
/// All arguments are optional.
/// code - Python code to execute
/// lineSeparator - separate code into lines. Defaults to $c(10).
Method StreamExecute(code As %Stream.GlobalCharacter, separateLines As %Boolean = {$$$YES}) As %Status
{
	#dim sc As %Status = $$$OK
	
	if separateLines = $$$YES {
		set code.LineTerminator = $c(10)
		
		while 'code.AtEnd {
			set line = code.ReadLine($$$MaxLocalLength)
			$$$TRACE("Var: " _ line)
			set sc = ##class(isc.py.Main).SimpleString(line)
			quit:$$$ISERR(sc)
		}	
	} else {
		set sc = ##class(isc.py.Main).ExecuteCode(code)
	}
	
	quit sc
}

}

