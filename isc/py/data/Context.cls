/// Python context
Class isc.py.data.Context Extends %Persistent
{

/// Short name.
Property Name As %String;

/// Extended info.
Property Description As %VarString;

/// List of variables.
Property Variables As list Of isc.py.data.Varable;

/// Array or loaded modules, key - module name, value - alias.
Property Modules As array Of %String(SQLPROJECTION = "table/column", STORAGEDEFAULT = "array");

/// History of executed commands. Currently does not work.
Property History As list Of %VarString;

/// Creation timestamp.
Property CreatedOn As %TimeStamp [ InitialExpression = {$ZDATETIME($ZTIMESTAMP, 3, 1, 3)} ];

/// Does not work
/// See https://stackoverflow.com/questions/53959362/how-to-get-history-from-python-c-api
Method PopulateHistory() As %Status
{
	#dim sc As %Status = $$$OK

	set count = ##class(isc.py.Callout).SimpleString("zzzcount=readline.get_current_history_length()", "zzzcount")
	do ##class(isc.py.Callout).SimpleString("del zzzcount")
	zw count
	for i=1:1:count {
		set item = ##class(isc.py.Callout).SimpleString("zzzitem=readline.get_history_item("_i_")", "zzzitem")
		zw item
	}
	do ##class(isc.py.Callout).SimpleString("del zzzitem")
	
	quit sc
}

/// Get modules and their aliases
Method PopulateModules() As %Status
{
    set modules = ##class(isc.py.Callout).SimpleString("zzzmodules=json.dumps(list(zzzmodulesfunc()))", "zzzmodules")
	do ##class(isc.py.Callout).SimpleString("del zzzmodules")

	set modules = {}.%FromJSON(modules)
	set iterator = modules.%GetIterator()
	while iterator.%GetNext(.key, .value) {
		set module = value.%Get(0)
		set alias = value.%Get(1)
		continue:module="builtins"
		do ..Modules.SetAt(alias, module)
	}
}

/// Get variables and their values.
Method PopulateVariables() As %Status
{
	#dim sc As %Status = $$$OK

	set variables = ##class(isc.py.Callout).SimpleString("zzzvars=json.dumps(list(zzzvarsfunc()))", "zzzvars")
	do ##class(isc.py.Callout).SimpleString("del zzzvars")

	set variables = {}.%FromJSON(variables)
	set iterator = variables.%GetIterator()
	while iterator.%GetNext(.key, .variable) {
		#dim varObj As isc.py.data.Varable
		set sc = ##class(isc.py.data.Varable).SaveVariable(variable, .varObj)
		quit:$$$ISERR(sc)
		do ..Variables.Insert(varObj)
	}
	
	quit sc
}

/// Define basic methods.
/// ToDo move to %OnNew?
Method Init()
{
	do ##class(isc.py.Callout).SimpleString("import types, json;") // readline
	do ##class(isc.py.Callout).SimpleString("def zzzmodulesfunc():"_ $c(10) _ 
											"    for name, val in globals().items():"_ $c(10) _
											"        if isinstance(val, types.ModuleType):"_ $c(10) _
											"            yield val.__name__, name")
	do ##class(isc.py.Callout).SimpleString("def zzzvarsfunc():"_ $c(10) _ 
											"    for name, val in globals().items():"_ $c(10) _
											"        if not (isinstance(val, types.ModuleType) or name.startswith('_') or hasattr(val, '__call__')):"_ $c(10) _
											"            yield name")
}

/// Save Python context on disk
/// set sc=##class(isc.py.data.Context).SaveContext()
ClassMethod SaveContext(Output context As isc.py.data.Context, verbose As %Boolean = {$$$NO}) As %Status
{
	set context = ..%New()
	do context.Init()
	//do obj.PopulateHistory()
	do context.PopulateModules()
	do context.PopulateVariables()
	do:verbose context.Display()
	
	quit context.%Save()
}

/// Restore context. Load modules and variables.
/// do ##class(isc.py.data.Context).RestoreContext()
ClassMethod RestoreContext(id As %Integer, verbose As %Boolean = {$$$NO}, clear As %Boolean = {$$$NO}) As %Status
{
	set context = ..%OpenId(id,,.sc)
	quit:$$$ISERR(sc) sc
	quit context.Restore(verbose, clear)
}

/// Internal restore method.
/// verbose - dispplay info about restored context.
/// clear - destroy environment before populating the context.
Method Restore(verbose As %Boolean = {$$$NO}, clear As %Boolean = {$$$NO}) As %Status
{
	do:clear ##class(isc.py.Callout).Finalize()
	
	// Restoring modules
	for {
  		set alias = ..Modules.GetNext(.module)
  		quit:(module = "")
  		do ##class(isc.py.Callout).SimpleString("import " _ module _ " as " _ alias)
	}
	
		
	// Restoring variables
	for i=1:1:..Variables.Count() {
		set variable = ..Variables.GetAt(i)
		do variable.Restore()
	}
	
	do:verbose ..Display()
	
	quit $$$OK
}

/// Wrapper for Display() method.
/// id - either an id of a stored context or empty for current context
/// do ##class(isc.py.data.Context).DisplayContext()
ClassMethod DisplayContext(id As %Integer = "")
{
	if id'="" {
		set context = ..%OpenId(id,,.sc)
		quit:$$$ISERR(sc) sc
	} else {
		set context = ..%New()
		do context.Init()
		do context.PopulateModules()
		do context.PopulateVariables()
	}
	
	do context.Display()
}

/// Display context
Method Display()
{
	set indent = "    "
	write "Name: " _ ..Name, !
	write "Description: " _ ..Description, !
	write "CreatedOn: " _ ..CreatedOn, !
	write "Modules:", !
	
	for {
  		set alias = ..Modules.GetNext(.module)
  		quit:(module = "")
  		write indent, module, " as ", alias, !
	}
	
	write "Variables:", !
	for i=1:1:..Variables.Count() {
		set variable = ..Variables.GetAt(i)
		do variable.Display(indent)
	}
}

Storage Default
{
<Data name="ContextDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Variables</Value>
</Value>
<Value name="5">
<Value>History</Value>
</Value>
<Value name="6">
<Value>CreatedOn</Value>
</Value>
</Data>
<Data name="Modules">
<Attribute>Modules</Attribute>
<Structure>subnode</Structure>
<Subscript>"Modules"</Subscript>
</Data>
<DataLocation>^isc.py.data.ContextD</DataLocation>
<DefaultData>ContextDefaultData</DefaultData>
<IdLocation>^isc.py.data.ContextD</IdLocation>
<IndexLocation>^isc.py.data.ContextI</IndexLocation>
<StreamLocation>^isc.py.data.ContextS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

