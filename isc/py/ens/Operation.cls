/// Sample operation. Executes Python code and returns requsted variables
Class isc.py.ens.Operation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "isc.py.ens.OutboundAdapter";

Property Adapter As isc.py.ens.OutboundAdapter;

XData MessageMap
{
<MapItems>
  <MapItem MessageType="isc.py.msg.StreamExecutionRequest">
    <Method>StreamExecute</Method>
  </MapItem>
  <MapItem MessageType="isc.py.msg.ExecutionRequest">
    <Method>Execute</Method>
  </MapItem>
  <MapItem MessageType="isc.py.msg.SaveRequest">
    <Method>SaveContext</Method>
  </MapItem>
  <MapItem MessageType="isc.py.msg.RestoreRequest">
    <Method>RestoreContext</Method>
  </MapItem>
  <MapItem MessageType="isc.py.msg.QueryRequest">
    <Method>ExecuteQuery</Method>
  </MapItem>
</MapItems>
}

/// Execute arbitrary Python code
Method Execute(request As isc.py.msg.ExecutionRequest, Output response As isc.py.msg.ExecutionResponse) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(isc.py.msg.ExecutionResponse).%New()
	set variables = $lfs(request.Variables)
	
	set variable = $lg(variables, 1)
	
	if request.SeparateLines = $$$YES {
		set lineSeparator = $c(10)
	} else {
		set lineSeparator = ""
	}
	
	set value = ..Adapter.Execute(request.Code, variable, lineSeparator, .sc)
	quit:$$$ISERR(sc) sc
	
	do:variable'="" response.Variables.SetAt(value, variable)
	
	for i=2:1:$ll(variables) {
		set variable = $lg(variables, i)
		continue:variable=""
		set value = ..Adapter.Execute("", variable, , .sc)
		do response.Variables.SetAt(value, variable)
		quit:$$$ISERR(sc)
	}
	
	quit sc
}

/// Execute arbitrary Python code
Method StreamExecute(request As isc.py.msg.StreamExecutionRequest, Output response As isc.py.msg.StreamExecutionResponse) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(isc.py.msg.StreamExecutionResponse).%New()
	set variables = $lfs(request.Variables)
	
	set sc = ..Adapter.StreamExecute(request.Code, request.SeparateLines)
	quit:$$$ISERR(sc) sc
	
	for i=1:1:$ll(variables) {
		set variable = $lg(variables, i)
		continue:variable=""
		kill stream
		set sc = ##class(isc.py.Main).GetVariable(variable, ##class(isc.py.Callout).#SerializationStr, .stream)
		do response.Variables.SetAt(stream, variable)
		quit:$$$ISERR(sc)
	}
	
	quit sc
}

/// Create pandas dataframe or list form sql.
Method ExecuteQuery(request As isc.py.msg.QueryRequest, Output response As Ens.Response) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(Ens.Response).%New()	
	set sc = ##class(isc.py.Main).ExecuteQuery(request.Query, request.Variable, request.Type, request.Namespace)
	quit sc
}

/// Save context
Method SaveContext(request As isc.py.msg.SaveRequest, Output response As Ens.StringResponse) As %Status
{
	#dim sc As %Status = $$$OK
	#dim context As isc.py.data.Context
	set sc = ##class(isc.py.data.Context).SaveContext(.context, request.MaxLength, request.Mask)
	quit:$$$ISERR(sc) sc
	
	set context.Name = request.Name
	set context.Description = request.Description
	set sc = context.%Save()
	quit:$$$ISERR(sc) sc
	
	set response = ##class(Ens.StringResponse).%New(context.%Id())
	
	quit sc
}

/// Restore context
Method RestoreContext(request As isc.py.msg.RestoreRequest, Output response As Ens.Response) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(isc.py.data.Context).RestoreContext(request.ContextId,, request.Clear)
	set response = ##class(Ens.Response).%New()
	quit sc
}

}

