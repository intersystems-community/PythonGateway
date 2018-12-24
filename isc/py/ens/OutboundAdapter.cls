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
/// Both arguments are optional.
/// code can be $c(10) or $c(13,10) delimited.
Method Execute(code = "", variable = "") As %String
{
	set codeList=$lfs(code, $c(10))
	
	for i=1:1:$ll(codeList)-1 {  
		do ##class(isc.py.Callout).SimpleString($lg(codeList, i))
	}
	set result = ##class(isc.py.Callout).SimpleString($lg(codeList, $ll(codeList)), variable)
	quit result
}

}

