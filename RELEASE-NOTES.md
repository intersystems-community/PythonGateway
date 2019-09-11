# Release notes

See [chagelog](CHANGELOG.md) for a full list of changes. This document marks the most important changes and offers some commentary.

## [0.8] - 2019-09-12

Download new release [from GitHub](https://github.com/intersystems-community/PythonGateway/releases).

Now for the new features.

**Fast transfer**. Pass globals, classes and tables from InterSystems IRIS to Python with ease and speed (3x faster than ODBC/JDBC driver and 10x faster than old `QueryExecute`). [Documentation](https://github.com/intersystems-community/PythonGateway/blob/master/DataTransfer.md).

**Proxy Gateway** allows generation of ObjectScript classes for Python classes. Instantinate objects, call object and class methods using familiar ObjectScript code ([docs](https://github.com/intersystems-community/PythonGateway/blob/master/Gateway.md)).
```
set module = "random"
set sc = ##class(isc.py.gw.Generator).Generate(module)
set sc = ##class(isc.py.Main).ImportModule(module)
write ##class(py.random).randint(1,100)
```

**Annotation evaluation** - business processes inheriting from `isc.py.ens.ProcessUtils` now can use activity annotations with variables which would be calculated on ObjectScript side before being passed to Python. 

**Jupyter support** - Jupyter can now be used to browse and edit Interoperability processes. [Documentation](https://github.com/intersystems-community/PythonGateway/tree/master/jupyter).

Last but not least and thanks to Benjamin De Boe we added **PMML support** via `isc.py.util.PMML` allowing imports of predictive models from Python into InterSystems IRIS via PMML.

**Installation instructions** are available in [Readme](https://github.com/intersystems-community/PythonGateway).

**Update instructions** (from v0.7):

1. Load new code and library [from GitHub](https://github.com/intersystems-community/PythonGateway/releases).

## [0.7] - 2019-03-22

First of all we're now public! You can download new release [from GitHub](https://github.com/intersystems-community/PythonGateway/releases).

Now for the new features.

We added **Docker support** and with that, Python Gateway runs instantly on any machine with Docker. Dockerfile builds upon InterSystems IRIS 2019.1 image. Alternatively, pull the prebuilt image from _intersystemscommunity_ on docker hub (write me a mail and I will add you to the organization).

Next feature is the ability to execute arbitrary Python functions in a structured and orderly way with the new **Execute Function API**. Here is a small preview on how it looks like:

```
set sc = ##class(isc.py.Main).ImportModule("random")
set sc = ##class(isc.py.Main).ExecuteFunctionArgs("random.randint", , ,.result, 1, 100)
write result, !
>26
```

**Proxyless Gateway** builds on top of that, offering `DynamicObject` class. Get and set object properties and execute object methods (and get results back):

```
set obj = ##class(isc.py.gw.DynamicObject).%New("Person", "p1", "'Ed'", "25", "'Test'")
write obj.name
>Ed
```

In Python modules and classes are objects too, so this works too:
```
set module = "random"
set sc = ##class(isc.py.Main).ImportModule(module)
set random = ##class(isc.py.gw.DynamicObject).%New(,module)
write random.randint(1,100)
>74
```
More examples of how you can use Proxyless Gateway and Execute Function API are available [here](https://github.com/intersystems-community/PythonGateway/blob/master/Gateway.md).

Next, **Execute Query API** (a basis for Interoperability RAW data transfer) saw considerable improvements. Now it can execute queries from any namespace and can transfer data of numeric, boolean and date/time types in addition to strings.

Interoperability productions now can retrieve variables as a **JSON**. Check test process to see how you can leverage it.

Saving process context now also saves user-defined functions.

You can now run **Python shell** from the terminal with either command:

- `do ##class(isc.py.util.Shell).Shell()`
- `zpy`

Users now can implement **initializer interface**. It allows you to define modules, functions and classes you want loaded with the start of the python process. Checkisc.py.init.Abstract class for implementation details. This option is available for both Interoperability and Terminal API users.

**Business Process emulator** from `isc.py.util.BPEmulator` class allows running Python-enabled business processes in a current terminal job, making testing, debugging and profiling intelligent business processes easier than ever before.

And many other bug fixes and improvements, check full changelog available [here](https://github.com/intersystems-community/PythonGateway/blob/master/Gateway.md).

**Installation instructions** are available in [Readme](https://github.com/intersystems-community/PythonGateway).

**Update instructions** (from v0.6):

1. Load new code and library [from GitHub](https://github.com/intersystems-community/PythonGateway/releases).
2. PythonLib setting should be reset again if it was set before the update.
3. All processes using RAW data ingestion method must be recompiled.
4. It is now a requirement to install dill module: `pip install dill`.
5. Reload test data: `do ##class(isc.py.test.CannibalizationData).Import()`

[0.8]: https://github.com/intersystems-community/PythonGateway/compare/v0.7...v0.8
[0.7]: https://github.com/intersystems-community/PythonGateway/compare/v0.6...v0.7
[0.7]: https://github.com/intersystems-community/PythonGateway/compare/v0.6...v0.7
