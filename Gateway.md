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

2. Create Proxy variable: `set obj = ##class(isc.py.gw.DynamicObject).%New("Person", "p1", , "'Ed'", "25", "'Test'")`
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
set sc = obj.%ToStream(,.stream)
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
set np =##class(isc.py.gw.DynamicObject).%New(,"np")
set arr =##class(isc.py.gw.DynamicObject).%New("np.array", "arr",,"[[1.5,2],[4,5]]")
set exp = np.exp(arr)
w $replace(exp.%GetString(),$c(10), $c(13,10))
```

And here's an example of setting property to proxy object:

```
do ##class(isc.py.init.Test).Initialize(,1)
set obj = ##class(isc.py.gw.DynamicObject).%New("Person", "p1", , "'Ed'", "25", "'Test'")
set obj2 = ##class(isc.py.gw.DynamicObject).%New("Person", "p2", , "'Bob'", "22", "'Test2'")
w obj.%GetJSON()

s obj.relative = obj2
s obj3 = obj.relative
w obj3.%GetJSON()

```

You can use `%EscapeOnSet` and `%EscapeOnCall` properties and `%IsPrimitive` method to affect default serialization behaviour.

# Proxy Gateway

Under development.

