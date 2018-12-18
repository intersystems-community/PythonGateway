# PythonAdapter
Python adapter via callout for InterSystems Data Platforms.

# Installation

1. Load ObjectScript code from [here](https://github.com/intersystems-ru/PythonAdapter/blob/master/isc/py/Callout.cls).
2. Place DLLs in `bin` folder.

# Use

```
do ##class(isc.py.Callout).Initialize()
write ##class(isc.py.Callout).SimpleString("x='ПРИВЕТ'","x")
write ##class(isc.py.Callout).SimpleString("x=repr('ПРИВЕТ')","x")
write ##class(isc.py.Callout).SimpleString("x=123","x")
write ##class(isc.py.Callout).Unload()
```


# Development

Development of ObjectScript is done via [cache-tort-git](https://github.com/MakarovS96/cache-tort-git) in UDL mode. 
Development of C code is done in Eclipse.


