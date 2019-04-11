/// Utils to redirect stdout
/// set r=##class(isc.py.util.Redirect).%New()
/// w r.Init()
/// w r.Enable(1)
/// w r.%GetString()
Class isc.py.util.Redirect Extends %RegisteredObject
{

/// Catcher IO
Property IO;

/// Old IO, whatever it was
Property OldIO;

/// Alias of the SYS module
Property SYS;

/// Devive name
Property Device As %String(VALUELIST = "stdout,stderr,stdin") [ InitialExpression = "stdout" ];

/// Init devices
Method Init()
{
	set sc = ##class(isc.py.Main).ImportModule("io",,.io)
	quit:$$$ISERR(sc) sc
	
	set sc = ##class(isc.py.Main).ImportModule("sys",,.sys)
	set ..SYS = sys
	quit:$$$ISERR(sc) sc
	
	set ..OldIO = ##class(isc.py.gw.DynamicObject).%GetNewVar()
	set sc = ##class(isc.py.Main).SimpleString(..OldIO _ "=" _ ..SYS _ "." _ ..Device)
	quit:$$$ISERR(sc) sc
	
	set ..IO = ##class(isc.py.gw.DynamicObject).%GetNewVar()
	set sc = ##class(isc.py.Main).SimpleString(..IO _ "=" _ io _ ".StringIO()")
	quit:$$$ISERR(sc) sc	
	
	
	quit sc
}

/// If new = 1 enables redirect, otherwise disables redirect
Method Enable(new As %Boolean = {$$$YES}) [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString(..SYS _ "."  _ ..Device _ "=" _ $case(new, $$$YES: ..IO, :..OldIO))
}

/// Get current device output.
/// If flush = 1 (default) then device would be cleaned after getting output.
Method GetString(flush As %Boolean = {$$$YES}) As %String
{
	set sc = ##class(isc.py.Main).SimpleString("zzzbuffer = " _ ..IO _ ".getvalue()", "zzzbuffer", , .zzzbuffer)
	quit:$$$ISERR(sc) sc
	
	set sc = ##class(isc.py.Main).SimpleString("del zzzbuffer")
	quit:$$$ISERR(sc) sc
	
	set:flush sc = ##class(isc.py.Main).SimpleString(..IO _ ".truncate(0)" _ $c(10) _ ..IO _ ".seek(0)")
	quit:$$$ISERR(sc) sc
	
	quit $replace(zzzbuffer, $c(10), $$$NL)
}

}

