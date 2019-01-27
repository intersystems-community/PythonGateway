/// Python context
Class isc.py.data.Context Extends %Persistent
{

/// Short name.
Property Name As %String;

/// Extended info.
Property Description As %VarString;

/// List of variables.
Property Variables As list Of isc.py.data.Variable;

/// Array or loaded modules, key - module name, value - alias.
Property Modules As array Of %String(SQLPROJECTION = "table/column", STORAGEDEFAULT = "array");

/// History of executed commands. Currently does not work.
Property History As list Of %VarString;

/// Creation timestamp.
Property CreatedOn As %TimeStamp [ InitialExpression = {$ZDATETIME($ZTIMESTAMP, 3, 1, 3)} ];

/// Alias of Pickle module, if any.
Property %PickleAlias As %String [ InitialExpression = "pickle", Transient ];

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
	#dim sc As %Status = $$$OK
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
	
	quit sc
}

/// Get variables and their values.
Method PopulateVariables(maxLength As %Integer = {$$$MaxStringLength}, mask As %String = "*") As %Status
{
	#dim sc As %Status = $$$OK

	set variables = ##class(isc.py.Callout).SimpleString("zzzvars=json.dumps(list(zzzvarsfunc()))", "zzzvars")
	do ##class(isc.py.Callout).SimpleString("del zzzvars")

	set variables = {}.%FromJSON(variables)
	
	set iterator = variables.%GetIterator()
	while iterator.%GetNext(.key, .variable) {
		#dim varObj As isc.py.data.Varable
		kill varObj
		if ##class(isc.py.util.Matcher).MatchOr(variable, mask) {
			set sc = ##class(isc.py.data.Variable).SaveVariable(variable, maxLength, .varObj)
			quit:$$$ISERR(sc)
			do:$isObject($g(varObj)) ..Variables.Insert(varObj)
		}

	}
	
	quit sc
}

/// Save Python context on disk
/// context - resulting context
/// maxLength - maximum length of saved variable. If veriable serialization is longer than that, it would be ignored. Set to 0 to get them all.
/// mask - comma separated list of variables to save. Special symbols * and ? are recognized. Set to * to get them all.
/// set sc=##class(isc.py.data.Context).SaveContext()
ClassMethod SaveContext(Output context As isc.py.data.Context, maxLength As %Integer = {$$$MaxStringLength}, mask As %String = "*", verbose As %Boolean = {$$$NO}) As %Status
{
	kill context
	set context = ..%New()
	set sc = ##class(isc.py.init.Default).Initialize(, verbose)
	set sc = context.PopulateModules()
	quit:$$$ISERR(sc) sc
	set sc = context.PopulateVariables(maxLength, mask)
	quit:$$$ISERR(sc) sc
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
	#dim sc As %Status = $$$OK
	do:clear ##class(isc.py.Callout).Finalize()
	
	set sc = ##class(isc.py.init.Default).Initialize(, verbose)
	quit:$$$ISERR(sc) sc
	set sc = ..InitPickle()
	quit:$$$ISERR(sc) sc
	
	// Restoring modules
	for {
  		set alias = ..Modules.GetNext(.module)
  		quit:(module = "")
  		set scModule = ##class(isc.py.Main).ImportModule(module, , alias)
  		set sc = $$$ADDSC(sc, scModule)
	}
		
	// Restoring variables
	for i=1:1:..Variables.Count() {
		#dim variable As isc.py.data.Variable
		set variable = ..Variables.GetAt(i)
		continue:variable.Pickle=""
		do variable.Restore($this)
	}
	
	do:verbose ..Display()
	
	quit sc
}

/// Calculate Pickle alias and import pickle if required
Method InitPickle(pickleName = "pickle") As %Status
{
	for {
  		set alias = ..Modules.GetNext(.module)
  		quit:(module = "")

  		if (module=pickleName) {
	  		set ..%PickleAlias = alias
	  		set importedPickle = $$$YES
  		}
	}
	
	quit ##class(isc.py.Main).ImportModule(pickleName, ,..%PickleAlias)
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
		set sc = ##class(isc.py.init.Default).Initialize()
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

