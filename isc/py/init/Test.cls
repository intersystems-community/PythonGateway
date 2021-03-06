/// Test initializer
/// do ##class(isc.py.init.Test).Initialize(,1)
Class isc.py.init.Test Extends isc.py.init.Abstract
{

Parameter Modules = {$lb("types", "json", "inspect", "random")};

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

ClassMethod InitPerson() As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString(  "class Person(object):" _ $c(10) _
									"    def __init__(self, name, age, city):" _ $c(10) _
									"        self.name = name" _ $c(10) _
									"        self.age = age" _ $c(10) _
									"        self.city = city" _ $c(10) _
									"    def getAge(self):" _ $c(10) _
									"        return self.age" _ $c(10) _
									"    def getAgePlus(self, add):" _ $c(10) _
									"        return self.age + add")
}

/// https://www.python-course.eu/python3_class_and_instance_attributes.php
ClassMethod InitZEmployee() As %Status [ CodeMode = expression ]
{
##class(isc.py.Main).SimpleString(  "class Employee(Person):" _ $c(10) _
									"    def __init__(self, name, age, city, company):" _ $c(10) _
									"        super().__init__(name, age, city)" _ $c(10) _
									"        self.company = company" _ $c(10) _
									"    def getCompany(self):" _ $c(10) _
									"        return self.company" _ $c(10) _
									"    def getAgePlus(self, add):" _ $c(10) _
									"        return self.age + add*2")
}

}

