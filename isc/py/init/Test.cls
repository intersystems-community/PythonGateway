/// Test initializer
Class isc.py.init.Test Extends isc.py.init.Abstract
{

Parameter Modules = {$lb("types", "json", $lb("pandas", "pd"), "inspect")};

ClassMethod InitCube() As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString(  "def cube(x):" _ $c(10) _ 
									"    return x*x*x")
}

ClassMethod InitArgs() As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString(  "def posargs(parg, *args):" _ $c(10) _ 
									"     print(""first positional arg:"", parg)" _ $c(10) _ 
									"     for arg in args:" _ $c(10) _ 
									"         print(""another arg through *args:"", arg)")
}

ClassMethod InitKWargs() As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString(  "def kwargs(name, **kwargs):" _ $c(10) _ 
									"     for key, value in kwargs.items():" _ $c(10) _ 
									"         print(""{0} = {1}"".format(key, value))")
}

/// * separates positional and keyword arguments
ClassMethod InitFoo() As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString(  "def foo(a, b, *, c, d=10):" _ $c(10) _ 
									"    pass")
}

ClassMethod InitAllargs() As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString(  "def allargs(parg, *args, name=1, **kwargs):" _ $c(10) _ 
									"     print(""first positional arg:"", parg)" _ $c(10) _ 
									"     for arg in args:" _ $c(10) _ 
									"         print(""arg from *argv:"", arg)" _ $c(10) _ 
									"     print(""first keyword arg name:"", name)" _ $c(10) _ 
									"     for key, value in kwargs.items():" _ $c(10) _ 
									"         print(""kwarg: {0} = {1}"".format(key, value))")
}

}

