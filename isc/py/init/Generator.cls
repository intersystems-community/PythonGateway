Class isc.py.init.Generator Extends isc.py.init.Abstract
{

Parameter Modules = {$lb("types", "json", "inspect", "random", "builtins", "collections")};

ClassMethod InitGetMembers() As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString(  "def zzzgetmembers(object, predicate):" _ $c(10) _ 
									"    return json.dumps([item[0] for item in inspect.getmembers(object, predicate)])")
}

}

