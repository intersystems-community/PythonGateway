/// Works on Cache and Ensemble (and InterSystems IRIS)
/// SELECT $ListToString(Columns) FROM isc_py_query.DataFrame('df')
Class isc.py.query.Custom
{

/// SELECT $ListToString(Columns) FROM isc_py_query.DataFrame('df')
Query DataFrame(variable) As %Query(ROWSPEC = "Columns:%List") [ SqlName = DataFrame, SqlProc ]
{
}

ClassMethod DataFrameExecute(ByRef qHandle As %Binary, variable) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(isc.py.Main).SimpleString("zzzcsv=" _ variable _ ".to_csv(index=False, header=False, sep=chr(" _ ##class(isc.py.query.Abstract).#Separator _ "), line_terminator=chr(" _ ##class(isc.py.query.Abstract).#Terminator _ "))")
	quit:$$$ISERR(sc) sc
	
	#dim stream As %Stream.GlobalCharacter
	set sc = ##class(isc.py.Main).GetVariable("zzzcsv", , .stream)
	quit:$$$ISERR(sc) sc	
	set sc = ##class(isc.py.Main).SimpleString("del zzzcsv")
	quit:$$$ISERR(sc) sc	
	
	set stream.LineTerminator = $char(##class(isc.py.query.Abstract).#Terminator)
	
	while 'stream.AtEnd {
		set str = stream.ReadLine()
		set list = $lfs(str, $char(##class(isc.py.query.Abstract).#Separator))
		set qHandle($i(qHandle)) = $lb(list)
	}
	
	set qHandle = $g(qHandle) + 1

	quit $$$OK
}

ClassMethod DataFrameFetch(ByRef qHandle As %Binary, ByRef Row As %List, ByRef AtEnd As %Integer = 0) As %Status [ PlaceAfter = DataFrameExecute ]
{
	if qHandle {
		set Row=$g(qHandle($increment(qHandle,-1)))
		set:qHandle=0 AtEnd = 1
	} else {
		set AtEnd=1
	}

	quit $$$OK
}

ClassMethod DataFrameClose(ByRef qHandle As %Binary) As %Status [ CodeMode = expression, PlaceAfter = DataFrameExecute ]
{
$$$OK
}

}

