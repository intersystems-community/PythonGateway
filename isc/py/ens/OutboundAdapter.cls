Class isc.py.ens.OutboundAdapter Extends Ens.OutboundAdapter
{

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

}

