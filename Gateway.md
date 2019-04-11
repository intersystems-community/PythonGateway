# Gateway functionality

This document describes functionality pertaining to what is commonly understood as (.Net/Java) Gateway.
There are three main parts:
- Execute Function
- Proxyless Gateway
- Proxy Gateway

# Execute function

Executes function by name. This API consists of two methods:
- `ExecuteFunction`
- `ExecuteFunctionArgs`

The difference between them is caller signature. `ExecuteFunction` accepts %List, %Collection.AbstractArray and JSON object separated into positional and keyword arguments. `ExecuteFunctionArgs` accepts `args...` and parses them into positional and keyword arguments. After that `ExecuteFunctionArgs` calls `ExecuteFunction`. 

It is caller responsibility to escape argument values. Use `isc.py.util.Converter` class to escape:
- string
- boolean
- date
- time
- timestamp

## ExecuteFunction

`ExecuteFunction` method from `isc.py.Main` class. Signature: 
- `function` - name of function to invoke. Can be nested, i.e. `random.randint`
- `variable` - name of python variable to write result to. 
- `positionalArguments` - positional arguments for Python function. Can be one of:
   + `$lb(val1, val2, ..., valN)`
   + `%Collection.AbstractIterator` object 
   + JSON array
- `keywordArguments` - keyword arguments for Python function. Can be one of:
   + `$lb($lb(name1, val1), $lb(name2, val2), ..., $lb(nameN, valN))`
   + `%Collection.AbstractArray` object
   + flat JSON object 
- `serialization` - how to serialize result
- `result` - write result into this variable

All arguments besides `function` are optional.

Here's an example of how it works:

```
set sc = ##class(isc.py.Main).ImportModule("random", ,.random)

set posList = $lb(1, 100)
set posCollection = ##class(%ListOfDataTypes).%New()
do posCollection.Insert(1)
do posCollection.Insert(100)
set posDynamic = [1, 100]

for positionalArguments = posList,posCollection,posDynamic {
	set sc = ##class(isc.py.Main).ExecuteFunction(random _ ".randint", positionalArguments,,,.result)
	write result,!
}

set kwList = $lb($lb("a", 1), $lb("b", 100))
set kwCollection = ##class(%ArrayOfDataTypes).%New()
do kwCollection.SetAt(1, "a")
do kwCollection.SetAt(100, "b")
set kwDynamic = { "a": 1, "b": 100}

for kwArguments = kwList,kwCollection,kwDynamic {
	set sc = ##class(isc.py.Main).ExecuteFunction(random _ ".randint", ,kwArguments,,.result)
	write result,!
}

set posList = $lb(1)
set kwDynamic = {"b": 100}
set sc = ##class(isc.py.Main).ExecuteFunction(random _ ".randint", posList, kwDynamic,,.result)
write result,!

set posList = ##class(isc.py.util.Converter).EscapeStringList($lb("Positional: {0} {1}! Keyword: {name}, {name2}", "Hello", "World"))
set kwDynamic = {"name":(##class(isc.py.util.Converter).EscapeString("Alice")), 
                 "name2":(##class(isc.py.util.Converter).EscapeString("Bob"))}
set sc = ##class(isc.py.Main).ExecuteFunction("str.format", posList, kwDynamic,,.result)
write result,!
```

## ExecuteFunctionArgs

`ExecuteFunctionArgs` method from `isc.py.Main` class. Signature: 
- `function` - name of function to invoke. Can be nested, i.e. `random.randint`
- `variable` - name of python variable to write result to. 
- `serialization` - how to serialize result
- `result` - write result into this variable
- `args...` - function arguments.

`ExecuteFunctionArgs` attempts to determine correct positional and keyword arguments from function signature (if available). It is recommended to call `ExecuteFunction` directly if `ExecuteFunctionArgs` is unable to construct a correct argument spec (and open an issue). Example: 

```
set sc = ##class(isc.py.Main).ImportModule("random", ,.random)
set sc = ##class(isc.py.Main).ExecuteFunctionArgs(random _ ".randint", , ,.result, 1, 100)
write result,!

set string = ##class(isc.py.util.Converter).EscapeString("Positional: {0}, {1}, {2}, {3}")
set arg1 = ##class(isc.py.util.Converter).EscapeString("Hello")
set arg2 = ##class(isc.py.util.Converter).EscapeString("World")
set arg3 = ##class(isc.py.util.Converter).EscapeString("Alice")
set arg4 = ##class(isc.py.util.Converter).EscapeString("Bob")
set sc = ##class(isc.py.Main).ExecuteFunctionArgs("str.format",,,.result, string, arg1, arg2, arg3, arg4)
write result,!

set string = ##class(isc.py.util.Converter).EscapeString("Positional: {0} {1}! Keyword: {name}, {name2}")
set arg1 = ##class(isc.py.util.Converter).EscapeString("Hello")
set arg2 = ##class(isc.py.util.Converter).EscapeString("World")
set kwargs = "**" _ {"name":"Alice","name2":"Bob"}.%ToJSON()
set sc = ##class(isc.py.Main).ExecuteFunctionArgs("str.format",,, .result, string, arg1, arg2, kwargs)
write result,!
```

# Proxyless Gateway

Proxyless gateway allows user to bind Python variables to InterSystems IRIS variables.
This allows user to:
- Get/Set object properties
- Call object methods
- Serialize variable to: Str, Repr, Pickle, Dill, JSON, Dynamic Object.

Example.

1. Load Python class `Person`: `do ##class(isc.py.init.Test).Initialize(,1)`

Note: here's `Person` class definition for reference:
```
class Person(object):
    def __init__(self, name, age, city):
        self.name = name
        self.age = age
        self.city = city
    def getAge(self):
        return self.age
    def getAgePlus(self, add):
        return self.age + add
```

2. Create Proxy variable: `set obj = ##class(isc.py.gw.DynamicObject).%New("Person", "p1", "'Ed'", "25", "'Test'")`
In this call we create Python variable `p1` of `Person` class and pass three methods to constructor `'Ed'`, `25` and `'Test'`.

3. Now we can interact with the object, let's get and set some properties:
```
write obj.name
set obj.name="Bob"
write obj.name
write obj.age
```
4. We can set some new properties too (unlike `ExecuteFunction` values are escaped automatically if `%EscapeOnSet` property is 1, which is default. You can also set properties to other dynamic objects. In that case unescaped python variable name would be used):
```
set obj.pet = "Dog"
write obj.pet
```

5. And we can call object methods:

```
write obj.getAge()
write obj.getAgePlus(10)
```

6. Finally we can convert object:
```
set sc = obj.%ToJSON(.json)
set sc = obj.%ToDynObj(.dynObj)
set sc = obj.%ToPickle(.pickle)
set sc = obj.%ToStream(.stream)
```

To create proxy object from existing proxy object just skip type argument:
```
kill obj
set p1 = ##class(isc.py.gw.DynamicObject).%New(, "p1")
```

Module objects can be proxied this way too:

```
set module = "random"
set sc = ##class(isc.py.Main).ImportModule(module)
set random = ##class(isc.py.gw.DynamicObject).%New(,module)
write random.randint(1,100)
```

Now for a more complex example. In case of primitives (int, bool, str, float) proxy object returns a serialized value. Otherwise (if  method call or variable get returns complex type) it returns another proxy object pointing to that result.  

```
set sc = ##class(isc.py.Main).ImportModule("numpy",,"np")
set np = ##class(isc.py.gw.DynamicObject).%New(,"np")
set arr = ##class(isc.py.gw.DynamicObject).%New("np.array", "arr","[[1.5,2],[4,5]]")
set exp = np.exp(arr)
write $replace(exp.%GetString(),$c(10), $c(13,10))
```

And here's an example of setting property to proxy object:

```
do ##class(isc.py.init.Test).Initialize(,1)
set obj = ##class(isc.py.gw.DynamicObject).%New("Person", "p1", "'Ed'", "25", "'Test'")
set obj2 = ##class(isc.py.gw.DynamicObject).%New("Person", "p2", "'Bob'", "22", "'Test2'")
write obj.%GetJSON()

set obj.relative = obj2
set obj3 = obj.relative
write obj3.%GetJSON()
```

You can use `%EscapeOnSet` and `%EscapeOnCall` properties and `%IsPrimitive` method to affect default serialization behaviour.

# Proxy Gateway

Create proxy ObjectScript classes. 

## Generation

Fastest way to generate classes is to run this command:
```
set modules = $lb("module1", ..., "moduleN") // or string in case there's only one module
set sc = ##class(isc.py.gw.Generator).Generate(modules)
```

It generates classes with all defaults. If you want more control you can instantiate generator object and finetune it's behavior by setting these properties:

- `LogLevel`- Display logging info. Increasing the number outputs more messages. Does not affect generation.
- `Package` - Base package for generated classes. Defaults to `py`. Defaults to 1, maximum is 3.
- `BaseClass` - Base class for all python classes. Defaults to `isc.py.gw.DynamicObject`.
- `FixClass` -  Class that fixes Method/Classmethod and Signatures. Defaults to `isc.py.util.Generator`. Must implement interfaces `GetArguments(type, method, ByRef arguments)` and `IsClassMethod(type, method) As %Boolean`.
- `*Mask` - White/Black masks for classes, methods and properties. 

1. Create generator object: `set generator = ##class(isc.py.gw.Generator).%New()`
2. Set `generator` object properties.
3. Call `GenerateModule` method to generate classes for one module (and all related classes).
4. After all modules were generated, call `Compile` method.

## Notes

1. It's extremely recommended to do class generation from a clean process (without imported modules).
2. Module generator does not support module aliases. Use canonical names only.
3. After generation it is user's responsibility to load modules before calling corresponding methods.
4. There's no distinction between class methods and instance methods in Python. That's why there's a number of heuristics implemented to determine the correct case. You can use Fixer class to deal with corner cases.
5. If there were compile errors, `Compile` method would try to produce fixes for some of them. Add them to your `FixClass` or open an issue.
6. All packages should be generated using the same `Package`.
7. `isc.py.util.Generator` contains a list of Modules import of which on default settings should succeed.

## Use

1. Let's generate `random` module: 
```
set module = "random"
set sc = ##class(isc.py.gw.Generator).Generate(module))
```
2. Now let's import the module: `set sc = ##class(isc.py.Main).ImportModule(module)`
3. We immediately can call functions of `random` module: `write ##class(py.random).randint(1,100)`
4. Let's init a `random.Random` object: `set rr = ##class(py.random.Random).%New()`
5. And call instance method: `write rr.betavariate(1,3)`

## Calling conventions

- Methods documentation is imported too - refer to it to know how to call the methods.
- To pass positional arguments or keyword arguments just pass their value.
- All arguments accept Python proxy objects and Python dynamic objects. `%Variable` is passed to function.
- It is caller responsibility to escape the values.
- To pass *args pass either %List or Dynamic Array.
- To pass **kwargs pass either: %List of %List(key, value) or Flat dynamic object.

### Calling example

Consider this function:

```
def allargs(parg, *args, name=1, **kwargs): 
     print('first positional arg:', parg) 
     for arg in args: 
         print('arg from *argv:', arg) 
     print('first keyword arg name:', name) 
     for key, value in kwargs.items(): 
         print('kwarg: {0} = {1}'.format(key, value))
```

It is a part of the `ed` module. As you can see it accepts all types of arguments. 

1. Install the module: `pip install ed`.
2. Generate classes: `set sc = ##class(isc.py.gw.Generator).Generate("ed")`
3. Import the module: `set sc = ##class(isc.py.Main).ImportModule("ed")`
4. As `allargs` function just prints to stdout and does not return anything we need to redirect stdout:
```
set redirect = ##class(isc.py.util.Redirect).%New()
do redirect.Init()
do redirect.Enable(1)
```
5. Here are different ways of calling `ed.allargs` function:
```
set parg = 1
set parg = ##class(isc.py.gw.DynamicObject).%New("int",,1)

set args = 3
set args = $lb(2,3)
set args = [2, 3]

set kwarg = 4
set kwarg = ##class(isc.py.gw.DynamicObject).%New("int",,4)

set kwargs = { "a":5, "b":6}
set kwargs = $lb($lb("a", 5), $lb("b",6))

set sc = ##class(py.ed).allargs(parg, args, kwarg, kwargs)

zwrite sc
write redirect.GetString()
```