# PythonAdapter
Python adapter via callout for InterSystems Data Platforms.

# Installation

1. Load ObjectScript code.
2. Place callout DLL in `bin` folder.
3. Check that your `PYTHONHOME` environment variable points to Python 3.6. 
4. Check that your SYSTEM `PATH` environment variable has PYTHONHOME.
5. Execute: `do ##class(isc.py.test.CannibalizationData).Import()` to populate test data

# Use

1. Call: `do ##class(isc.py.Callout).Setup()` once per systems start (add to ZSTART!)
2. Call: `do ##class(isc.py.Callout).Initialize()` once per process
3. Call main method (can be called many times, context persists): `write ##class(isc.py.Callout).SimpleString(code, data)`
4. Call: `do ##class(isc.py.Callout).Finalize()` to free Python context
5. Call: `write ##class(isc.py.Callout).Unload()` to free callout library

```
do ##class(isc.py.Callout).Setup() 
do ##class(isc.py.Callout).Initialize()
write ##class(isc.py.Callout).SimpleString("x='ПРИВЕТ'","x")
write ##class(isc.py.Callout).SimpleString("x=repr('ПРИВЕТ')","x")
write ##class(isc.py.Callout).SimpleString("x=123","x")
do ##class(isc.py.Callout).Finalize()
write ##class(isc.py.Callout).Unload()
```


# Development

Development of ObjectScript is done via [cache-tort-git](https://github.com/MakarovS96/cache-tort-git) in UDL mode. 
Development of C code is done in Eclipse.


