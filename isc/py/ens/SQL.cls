Include %occErrors

Class isc.py.ens.SQL
{

/// Execute arbitrarty query. 
/// query - sql statement or class:Query or class:XData
/// args - query arguments if any
/// w $System.Status.GetErrorText(##class(isc.py.ens.SQL).Execute())
ClassMethod Execute(query, args...) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ..GetSQL(query, .sql)
	quit:$$$ISERR(sc) sc
	
	set st = ##class(%SQL.Statement).%New()
	set sc = st.%Prepare(sql)
	quit:$$$ISERR(sc) sc
	
	#dim result As %SQL.StatementResult
	set result = st.%Execute(args...)
	
	if result.%SQLCODE'=0 {
		set sc = $System.Status.Error($$$SQLError, result.%SQLCODE, result.%Message)
	}
	
	quit sc
}

/// w ##class(isc.py.ens.SQL).GetSQL("SELECT 1")
/// w ##class(isc.py.ens.SQL).GetSQL("class:Query")
/// w ##class(isc.py.ens.SQL).GetSQL("class:XData")
ClassMethod GetSQL(query, Output sql) As %Status
{
	#dim sc As %Status = $$$OK
	set sql = ""
		
	if (($l(query, ":")=2) && (##class(%Dictionary.CompiledClass).%ExistsId($p(query, ":")))) {
		set classname = $p(query, ":")
		set element = $p(query, ":", 2)
		
		if ##class(%Dictionary.QueryDefinition).IDKEYExists(classname, element) {
			set sql =  ..GetClassQuery(classname, element)
		} elseif ##class(%Dictionary.XDataDefinition).IDKEYExists(classname, element) {
			set sql = ..GetClassXData(classname, element)
		} else {
			set sc = $$$ERROR($$$GeneralError, $$$FormatText("Class %1 does not have Query or XData named %2", class, queryName))
		}
	} else {
		set sql = query
	}
	quit sc
}

/// Get XData contents from classname
/// w ##class(isc.py.ens.SQL).GetClassXData("isc.py.test.Process", "BPL")
ClassMethod GetClassXData(classname, xdata) As %String
{
	set str = ""
	for i=1:1:$$$comMemberKeyGet(classname,$$$cCLASSxdata,xdata,$$$cXDATAdata) {
		set str = str _ $$$comMemberArrayGet(classname,$$$cCLASSxdata,xdata,$$$cXDATAdata,i) _ $$$NL
	}
	quit str
}

/// Get Query contents from classname
/// w ##class(isc.py.ens.SQL).GetClassQuery("", "")
ClassMethod GetClassQuery(classname, query) As %String [ CodeMode = expression ]
{
$$$comMemberKeyGet(classname,$$$cCLASSquery,query,$$$cQUERYsqlquery)
}

/// do ##class(isc.py.ens.SQL).Test()
ClassMethod Test()
{
	set req = ##class(isc.py.msg.SQLRequest).%New()
	set req.Query = "INSERT INTO test.p (City, Name, Phone) VALUES (?, ?, ?)"
	do req.Args.Insert(4)
	do req.Args.Insert(5)
	do req.Args.Insert(6)
	
	set sc = ##class(EnsLib.Testing.Service).SendTestRequest("isc.py.ens.Operation", req, .resp, .sessionId, $$$YES)
	w $System.Status.GetErrorText(sc),!
	zw resp,sessionId
}

}

