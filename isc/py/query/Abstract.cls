Class isc.py.query.Abstract [ Abstract ]
{

Parameter SQLNAME As String = "Abstract";

Parameter Separator = 1;

Parameter Terminator = 2;

Property %Data As %Stream.GlobalCharacter [ Private ];

Property %DTypes As %DynamicObject [ Private ];

Method %OpenCursor(variable As %String) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(isc.py.Main).SimpleString("zzzcsv=" _ variable _ ".to_csv(index=False, header=False, sep=chr(" _ ..#Separator _ "), line_terminator=chr(" _ ..#Terminator _ "))")
	quit:$$$ISERR(sc) sc
	
	#dim stream As %Stream.GlobalCharacter
	set sc = ##class(isc.py.Main).GetVariable("zzzcsv", , .stream)
	quit:$$$ISERR(sc) sc	
	set sc = ##class(isc.py.Main).SimpleString("del zzzcsv")
	quit:$$$ISERR(sc) sc	
	
	set stream.LineTerminator = $char(..#Terminator)
	
	set ..%Data = stream
	
	set sc = ##class(isc.py.Main).GetVariableJson(variable _ ".dtypes", .dtypes, $$$YES)
	quit:$$$ISERR(sc) sc
	
	set ..%DTypes = {}.%FromJSON(dtypes)
	
	quit sc
}

Method GetRow(Output atEnd As %Boolean) As %List
{
	if '..%Data.AtEnd {
		set list = $lfs(..%Data.ReadLine(), $char(..#Separator))
		set atEnd = $$$NO
	} else {
		set list = ""
		set atEnd = $$$YES
	}
	return list
}

}

