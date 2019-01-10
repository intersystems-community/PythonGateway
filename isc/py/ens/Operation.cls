/// Sample operation. Executes Python code and returns requsted variables
Class isc.py.ens.Operation Extends Ens.BusinessOperation
{

Parameter ADAPTER = "isc.py.ens.OutboundAdapter";

Property Adapter As isc.py.ens.OutboundAdapter;

/// This is the default message handler.  All request types not declared in the message map are delivered here
Method OnMessage(request As isc.py.ens.Request, Output response As isc.py.ens.Response) As %Status
{
	set response = ##class(isc.py.ens.Response).%New()
	set variables = $lfs(request.Variables)
	quit:'$Listvalid(variables) $$$ERROR($$$AttributeValueMustBeList, "variables")
	
	set variable = $lg(variables, 1)
	
	if request.SeparateLines = $$$YES {
		set lineSeparator = $c(10)
	} else {
		set lineSeparator = ""
	}
	
	set value = ..Adapter.Execute(request.Code, variable, lineSeparator)
	
	do:variable'="" response.Variables.SetAt(value, variable)
	
	for i=2:1:$ll(variables) {
		set variable = $lg(variables, i)
		continue:variable=""
		set value =  ..Adapter.Execute("", variable)
		do response.Variables.SetAt(value, variable)
	}
	
	quit $$$OK
}

}

