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
	
	for i=1:1:$ll(codeList)-1 {
		set line = $lg(codeList, i)
		$$$TRACE(line)
		do ##class(isc.py.Callout).SimpleString(line)
		set sc = ##class(isc.py.Callout).GetStatus()
		if $$$ISERR(sc) {
			set sc = $$$ADDSC($$$ERROR($$$GeneralError, "Code: " _ line), sc)
			/// TODO continue despite error?
			quit
		}
	}
	quit:$$$ISERR(sc) ""
	
	set line = $lg(codeList, $ll(codeList))
	$$$TRACE(line)
	set result = ##class(isc.py.Callout).SimpleString(line, variable)
	set sc = ##class(isc.py.Callout).GetStatus()
	set:$$$ISERR(sc) sc = $$$ADDSC($$$ERROR($$$GeneralError, "Code: " _ line _ ", Variable: " _ variable), sc)
	quit result
}

}

