# Gateway functionality

This document describes functionality pertrainig to what is commonly understood as (.Net/Java) Gateway.
There are three main parts:
- Execute Function
- Proxyless Gateway
- Proxy Gateway


# Execute function

Consists of `ExecuteFunction` method from `isc.py.Main` class. Signature: 
- `function` - name of function to invoke. Can be nested, i.e. `random.randint`  
- `positionalArguments` - positional argumets for Python function. Can be one of:
   + `$lb(val1, val2, ..., valN)`
   + `%Collection.AbstractIterator` object 
   + JSON array
- keywordArguments - keyword argumets for Python function. Can be one of:
   + `$lb($lb(name1, val1), $lb(name2, val2), ..., $lb(nameN, valN))`
   + `%Collection.AbstractArray` object
   + flat JSON object 
- `serialization` - how to serialize result
- `result` - write result into this variable

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
