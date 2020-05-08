/// SELECT $ListToString(Columns) FROM isc_py_query.List('df')
Class isc.py.query.List Extends (isc.py.query.Abstract, %SQL.CustomQuery)
{

Parameter SQLNAME As String = "List";

Property Columns As %List;

Method %FetchCursor() As %Integer
{
	set ..Columns = ..GetRow(.atEnd)
	quit 'atEnd
}

}

