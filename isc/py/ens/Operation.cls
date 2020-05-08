/// Sample operation. 
/// Process requests to:
///  - Execute Python code and return requsted variables (string/stream)
///  - Save/Restore context
///  - Load data into Python
Class isc.py.ens.Operation Extends Ens.BusinessOperation
{

/// Linux only. Path (or just the filename) to python shared lib 
/// Due to the problems with lib-dynload, sometimes library file should be loaded explicitly on Linux
/// For more info see: https://bugs.python.org/issue4434
/// Do not use it, unless you get errors like: undefined symbol: _Py_TrueStruct and similar
/// In cause of problems set to: "libpython3.6m.so"
Property PythonLib As %String(MAXLEN = 1000);

/// Class implementing isc.py.init.Abstract interface.
/// Can be used to load modules and functions on process startup.
Property Initializer As %String;

Parameter SETTINGS = "PythonLib:Basic,Initializer:Basic:selector?context={isc.py.ens.ContextSearch/SubclassOf?class=isc.py.init.Abstract}";

Method OnInit() As %Status
{
	#dim sc As %Status = $$$OK
	set:..PythonLib'="" sc = ##class(isc.py.Callout).Initialize(..PythonLib)
	quit:$$$ISERR(sc) sc
	
	if (..Initializer'="") {
		if ##class(%Dictionary.CompiledClass).%ExistsId(..Initializer) {
			set sc = $classmethod(..Initializer, "Initialize") 
		} else {
			set sc = $$$ERROR($$$GeneralError, "Initializer class does not exist or is uncompiled: ", ..Initializer) 
		}
	}
	quit sc
}

/// Free Python library
Method OnTearDown() As %Status
{
	do ##class(isc.py.Callout).Finalize()
	do ##class(isc.py.Callout).Unload()
	quit $$$OK
}

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
    <MapItem MessageType="isc.py.msg.GlobalRequest">
    <Method>ExecuteGlobal</Method>
  </MapItem>
    <MapItem MessageType="isc.py.msg.ClassRequest">
    <Method>ExecuteClass</Method>
  </MapItem>
  <MapItem MessageType="isc.py.msg.TableRequest">
    <Method>ExecuteTable</Method>
  </MapItem>
  <MapItem MessageType="isc.py.msg.DebugRequest">
    <Method>Debug</Method>
  </MapItem>
  <MapItem MessageType="isc.py.msg.CreateCQRequest">
    <Method>CreateCustomQuery</Method>
  </MapItem>
    <MapItem MessageType="isc.py.msg.SQLRequest">
    <Method>SQL</Method>
  </MapItem>
</MapItems>
}

/// Execute arbitrary Python code
Method Execute(request As isc.py.msg.ExecutionRequest, Output response As isc.py.msg.ExecutionResponse) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(isc.py.msg.ExecutionResponse).%New()
	
	if request.SeparateLines = $$$YES {
		set codeList=$lfs(request.Code, $c(10))
	} else {
		set codeList=$lb(request.Code)
	}
	
	for i=1:1:$ll(codeList) {
		set line = $lg(codeList, i)
		continue:line=""
		$$$TRACE(line)	
		set sc = ##class(isc.py.Main).SimpleString(line)
		quit:$$$ISERR(sc)
	}
	quit:$$$ISERR(sc) sc
	
	set serialization = request.Serialization
	set variables = $lfs(request.Variables)
	for i=1:1:$ll(variables) {
		set variable = $lg(variables, i)
		continue:variable=""
		$$$TRACE("Getting variable: " _ variable)
		
		kill value
		
		if ((serialization = "Str") || (serialization = "Repr")) {
			set sc = ##class(isc.py.Main).SimpleString(, variable, $parameter("isc.py.Callout", "Serialization" _ serialization), .value)
		} elseif (serialization = "JSON") {
			set sc = ##class(isc.py.Main).GetVariableJson(variable, .value, $$$YES)
		} elseif ((serialization = "Pickle") || (serialization = "Dill")) {
			set sc = ##class(isc.py.Main).GetVariablePickle(variable, .value, $$$YES, (serialization="Dill"))
		}
		quit:$$$ISERR(sc)
		do response.Variables.SetAt(value, variable)
	}
	
	quit sc
}

/// Execute arbitrary Python code
Method StreamExecute(request As isc.py.msg.StreamExecutionRequest, Output response As isc.py.msg.StreamExecutionResponse) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(isc.py.msg.StreamExecutionResponse).%New()
	
	
	set code = request.Code
	
	if request.SeparateLines = $$$YES {
		set code.LineTerminator = $c(10)
		
		while 'code.AtEnd {
			set line = code.ReadLine($$$MaxLocalLength)
			$$$TRACE(line)
			set sc = ##class(isc.py.Main).SimpleString(line)
			quit:$$$ISERR(sc)
		}	
	} else {
		set sc = ##class(isc.py.Main).ExecuteCode(code)
	}
	
	quit:$$$ISERR(sc) sc
	
	set serialization = request.Serialization
	set variables = $lfs(request.Variables)
	for i=1:1:$ll(variables) {
		set variable = $lg(variables, i)
		continue:variable=""
		$$$TRACE("Getting variable: " _ variable)
		
		kill stream
		
		if ((serialization = "Str") || (serialization = "Repr")) {
			set sc = ##class(isc.py.Main).GetVariable(variable, $parameter("isc.py.Callout", "Serialization" _ serialization), .stream)
		} elseif (serialization = "JSON") {
			set sc = ##class(isc.py.Main).GetVariableJson(variable, .stream)
		} elseif ((serialization = "Pickle") || (serialization="Dill")) {
			set sc = ##class(isc.py.Main).GetVariablePickle(variable, .stream, , (serialization="Dill"))
		}		
		quit:$$$ISERR(sc)
		do response.Variables.SetAt(stream, variable)
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

/// Create pandas dataframe or list form global.
Method ExecuteGlobal(request As isc.py.msg.GlobalRequest, Output response As Ens.Response) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(Ens.Response).%New()
	set sc = ##class(isc.py.Main).ExecuteGlobal(request.Global, request.Variable, request.Type, request.Start, request.End, request.Mask, request.Labels, request.Namespace)
	quit sc
}

/// Create pandas dataframe or list form class.
Method ExecuteClass(request As isc.py.msg.ClassRequest, Output response As Ens.Response) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(Ens.Response).%New()
	set sc = ##class(isc.py.Main).ExecuteClass(request.Class, request.Variable, request.Type, request.Start, request.End, request.Properties, request.Namespace)
	quit sc
}

/// Create pandas dataframe or list form table.
Method ExecuteTable(request As isc.py.msg.TableRequest, Output response As Ens.Response) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(Ens.Response).%New()
	set sc = ##class(isc.py.Main).ExecuteTable(request.Table, request.Variable, request.Type, request.Start, request.End, request.Properties, request.Namespace)
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

/// Works only in Foreground mode on Windows
Method Debug(request As isc.py.msg.DebugRequest, Output response As Ens.Response) As %Status
{
	#dim sc As %Status = $$$OK
	set response = ##class(Ens.Response).%New()
	break
	quit sc
}

/// Create Custom Query class from DataFrame
Method CreateCustomQuery(request As isc.py.msg.CreateCQRequest, Output response As Ens.Response) As %Status
{
	#dim sc As %Status = $$$OK
	set sc = ##class(isc.py.query.Generator).Generate(request.Variable, request.Classname)
	set response = ##class(Ens.Response).%New()
	quit sc
}

/// Execute arbitrary query against InterSystems IRIS
Method SQL(request As isc.py.msg.SQLRequest, Output response As Ens.Response) As %Status
{
	#dim sc As %Status = $$$OK
	
	set args = request.Args.Count()
	for i=1:1:request.Args.Count() {
		set args(i) = request.Args.GetAt(i)
	}
	
	set sc = ##class(isc.py.ens.SQL).Execute(request.Query, args...)
	break
	set response = ##class(Ens.Response).%New()
	quit sc
}

}

