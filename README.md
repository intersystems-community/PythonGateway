# PythonAdapter
Python adapter via callout for InterSystems Data Platforms.

# Installation

0. [Install Python 3.6.7 64 bit](https://www.python.org/downloads/release/python-367/).
1. Load ObjectScript code (i.e. `do $system.OBJ.LoadDir("C:\InterSystems\Repos\Python\isc\py\","*.cls",,1)`).
2. Place [callout DLL/SO/DYLIB](https://github.com/intersystems-ru/PythonAdapter/releases) in the `bin` folder of your InterSystems IRIS installation. Library file should be placed into a path returned by `write ##class(isc.py.Callout).GetLib()`. 

## Windows 

3. Check that your `PYTHONHOME` environment variable points to Python 3.6.7.
4. Check that your SYSTEM `PATH` environment variable has `PYTHONHOME` variable (or directory it points to).

## Linux && Mac

3. Check that your SYSTEM `PATH` environment variable has `/usr/lib` and `/usr/lib/x86_64-linux-gnu`, preferably at the begining. Use `/etc/environment` file to set environment variables.

If you modified environment variables restart your InterSystems product.

## Docker

1. To build docker image:
  - Copy `iscpython.so` into repository root (if it's not there)
  - Execute in repository root `docker build --force-rm --tag irispy/iris:2019.1 .`
2. To run docker image execute: 

```
docker run -d \
  -p 52773:52773 \
  -v /<HOST-DIR-WITH-iris.key>/:/mount \
  --name irispy \
  irispy/iris:2019.1 \
  --key /mount/iris.key \
```
3. Test process `isc.py.test.Process` saves image aftifact into temp directory. You might want to change that path to a monted directory. To do that edit annotation for `Correlation Matrix: Graph` call, specifying valid filepath for `f.savefig` function.
4. For terminal access execute: `docker exec -it irispy sh`.
5. Access SMP with SuperUser/SYS or Admin/SYS users.
6. To stop container execute: `docker stop irispy && docker rm --force irispy`.

# Use

1. Call: `set sc = ##class(isc.py.Callout).Setup()` once per systems start (add to ZSTART: [docs](https://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GSTU_customize#GSTU_customize_startstop), [sample](https://gist.githubusercontent.com/eduard93/412ed81e2bf619269ab4a49d939d2304/raw/c9d5f922827db5052b6e1195616d333ffe7dc1ec/%2525ZSTART)).
2. Call main method (can be called many times, context persists): `write ##class(isc.py.Main).SimpleString(code, variable, , .result)`
3. Call: `set sc = ##class(isc.py.Callout).Finalize()` to free Python context.
4. Call: `set sc = ##class(isc.py.Callout).Unload()` to free callout library.

```
set sc = ##class(isc.py.Callout).Setup() 
set sc = ##class(isc.py.Main).SimpleString("x='HELLO'", "x", , .x)
write x
set sc = ##class(isc.py.Callout).Finalize()
set sc = ##class(isc.py.Callout).Unload()
```

Generally the main interface to Python is `isc.py.Main`. It offers these methods (all return `%Status`):

- `SimpleString(code, returnVariable, serialization, .result)` - for cases where both code and variable are strings.
- `ExecuteCode(code, variable)` - execute `code` (it may be a stream or string), optionally ser result into `variable`.
- `GetVariable(variable, serialization, .stream, useString)` - get `serialization` of `variable` in `stream`. If `useString` is 1 and variable serialization can fit into string then string is returned instead of the stream.
-  `GetVariableInfo(variable, serialization, .defined, .type, .length)` - get info about variable: is it defined, type,and serialization length.
- `GetStatus()` - returns last occured exception in Python and clears it.
- `GetVariableJson(variable, .stream, useString)` - get JSON serialization of variable.
- `GetVariablePickle(variable, .stream, useString)` - get Pickle serialization of variable.
- `ExecuteQuery(query, variable, type)` - create resultset (pandas `dataframe` or `list`) from sql query and set it into `variable`.
- `ImportModule(module, .imported, .alias)` -  import module with alias.
- `GetModuleInfo(module, .imported, .alias)` - get module alias and is it currently imported.

Possible Serializations:
- `##class(isc.py.Callout).SerializationStr` - Serialization by str() function
- `##class(isc.py.Callout).SerializationRepr` - Serialization by repr() function

# Context persistence

Python context can be persisted into InterSystems IRIS and restored later on. There are currently three public functions:

- Save context: `set sc = ##class(isc.py.data.Context).SaveContext(.context, maxLength, mask, verbose)` where `maxLength` - maximum length of saved variable. If veriable serialization is longer than that, it would be ignored. Set to 0 to get them all, `mask` - comma separated list of variables to save (special symbols * and ? are recognized), `verbose` specifies displaying context after saving, and `context` is a resulting Python context. Get context id with `context.%Id()`
- Display context: `do ##class(isc.py.data.Context).DisplayContext(id)` where `id` is an id of a stored context. Leave empty to display current context.
- Restore context: `do ##class(isc.py.data.Context).RestoreContext(id, verbose, clear)` where `clear` kills currently loaded context if set to 1.

Context is saved into `isc.py.data` package and can be viewed/edited by SQL and object methods.

# Interoperability adapter

Interoperability adapter `isc.py.ens.Operation` offers ability to interact with Python process from Interoperability productions. Currently five requests are supported:

- Execute Python code via `isc.py.msg.ExecutionRequest`. Returns `isc.py.msg.ExecutionResponse` with requested variable values
- Execute Python code via `isc.py.msg.StreamExecutionRequest`. Returns `isc.py.msg.StreamExecutionResponse` with requested variable values. Same as above, but accepts and returns streams instead of strings.
- Set dataset from SQL Query with `isc.py.msg.QueryRequest`. Returns `Ens.Response`.
- Save Python conext via `isc.py.msg.SaveRequest`. Returns `Ens.StringResponse` with context id.
- Restore Python context via `isc.py.msg.RestoreRequest`.

Check request/response classes documentation for details.

# Test Business Process

Along with callout code and Interoperability adapter there's also a test Interoperability Production and test Business Process. To use them:

1. In OS bash execute `pip install  pandas matplotlib seaborn`. 
2. Execute: `do ##class(isc.py.test.CannibalizationData).Import()` to populate test data.
3. In test Business Process `isc.py.test.Process` edit annotation for `Correlation Matrix: Graph` call, specifying valid filepath for `f.savefig` function.
4. Save and compile business process.
5. Start `isc.py.test.Production` production.
6. Send empty `Ens.Request` mesage to the `isc.py.test.Process`.

### Notes

- If you want to use `ODBC` connection, on Windows install pyodbc: `pip install pyodbc`, on Linux install: `apt-get install unixodbc unixodbc-dev python-pyodbc`. 
- If you want to use `JDBC` connection, install JayDeBeApi: `pip install JayDeBeApi`. On linux you might need to install: `apt-get install python-apt` beforehand. 
- If you get errors similar to `undefined symbol: _Py_TrueStruct` in `isc.py.ens.Operation`operation set setting `PythonLib` to `libpython3.6m.so` or even to a full path of the shared library.
- In test Business Process `isc.py.test.Process` edit annotation for `ODBC` or `JDBC` calls, specifying correct connection string.
- In production, `isc.py.test.Process` host set `ConnectionType` setting to a preferred connection type (defaults to `RAW`, change only if you need to test xDBC connectivity).

# Unit tests

To run tests execute:

```
set repo = ##class(%SourceControl.Git.Utils).TempFolder()
set ^UnitTestRoot = ##class(%File).SubDirectoryName(##class(%File).SubDirectoryName(##class(%File).SubDirectoryName(repo,"isc"),"py"),"unit",1)
set sc = ##class(%UnitTest.Manager).RunTest(,"/nodelete")
```

# ZLANGC00

Install [this ZLANG routine](https://gist.githubusercontent.com/eduard93/2c3159c7dc71f03c4081a99093d8ff37/raw/3bc83f2dc7348ea11ab982b0e3d54cfcef198d17/%2525ZLANGC00.xml) to add `zpy` command:

```
zpy "import random"
zpy "x=random.random()"
zpy "x"
>0.4157151243124494
```

# Limitations

There are several limitaions associated with the use of PythonAdapter.

1. Modules reinitialization. Some modules may only be loaded once diring process lifetime (i.e. numpy). While Finalization clears the context of the process, repeated load of such libraries terminates the process. Discussions: [1](https://stackoverflow.com/questions/14843408/python-c-embedded-segmentation-fault), [2](https://stackoverflow.com/questions/7676314/py-initialize-py-finalize-not-working-twice-with-numpy).
2. Variables. Do not use these variables: `zzzcolumns`, `zzzdata`, `zzzdef`, `zzzalias`, `zzzerr`, `zzzvar`, `zzztype`, `zzzlen`, `zzzjson`, `zzzpickle`, `zzzcount`, `zzzitem`, `zzzmodules`, `zzzvars`. Please report any leakage of these variables. System code should always clear them.
3. Functions  Do not redefine these functions `zzzmodulesfunc()`, `zzzvarsfunc()`, `zzzgetalias()`, `zzztoserializable()`.
4. Context persistence. Only pickled variables could be restored correctly. User functions are currently not supported. Module imports are supported.

# Development

Development of ObjectScript is done via [cache-tort-git](https://github.com/MakarovS96/cache-tort-git) in UDL mode. 
Development of C code is done in Eclipse.

# Building

## Windows

1. Install [MinGW-w64](https://sourceforge.net/projects/mingw-w64/) you'll need `make` and `gcc`. 
2. Rename `mingw32-make.exe` to `make.exe` in `mingw64\bin` directory.
3. Set `GLOBALS_HOME` environment variable to the root of Caché or Ensemble installation.
4. Set `PYTHONHOME` environment variable to the root of Python3 installation. Usually `C:\Users\<User>\AppData\Local\Programs\Python\Python3<X>`
5. Open MinGW bash (`mingw64env.cmd`).
6. In `<Repository>\c\` execute `make`.

## Linux

It's recommended to use Linux os which uses python3 by default, i.e. Ubuntu 18.04.1 LTS. Skip steps 1 and maybe even 2 if your OS has python 3.6 as default python (`python3 --version` or `python --version` or `python3.6 --version`).

1. Add Python 3.6 repo: `add-apt-repository ppa:jonathonf/python-3.6` and `apt-get update`
2. Install: `apt install python3.6 python3.6-dev libpython3.6-dev build-essential`
3. Set `GLOBALS_HOME` environment variable to the root of Caché or Ensemble installation.
4. Set environment variable `PYTHONVER` to the python version you want to build, i.e.: `export PYTHONVER=3.6`
5. In `<Repository>/c/` execute `make`.


## Mac OS X

1. Install Python 3.6 and gcc compiler.
2. Set `GLOBALS_HOME` environment variable to the root of Caché or Ensemble installation.
3. Set environment variable `PYTHONVER` to the python version you want to build, i.e.: ` export PYTHONVER=3.6`
2. In `<Repository>/c/` execute:

```
gcc -Wall -Wextra -fpic -O3 -fno-strict-aliasing -Wno-unused-parameter -I/Library/Frameworks/Python.framework/Versions/${PYTHONVER}/Headers -I${GLOBALS_HOME}/dev/iris-callin/include -c -o iscpython.o iscpython.c

gcc -dynamiclib -L/Library/Frameworks/Python.framework/Versions/${PYTHONVER}/lib -L/usr/lib -lpython${PYTHONVER}m -lpthread -ldl -lutil -lm -Xlinker iscpython.o -o iscpython.dylib
```

If you have a Mac please update makefile so we can build Mac version via Make. 


# Troubleshooting

## `<DYNAMIC LIBRARY LOAD>` exception

1. Check that OS has correct python installed. Open python, execute this script: 

```
import sys
sys.version
``` 

The result should contain: `Python 3.6.7` and `64 bit`. If it's not, [install Python 3.6.7 64 bit](https://www.python.org/downloads/release/python-367/).

2. Check OS-specific instsallation steps. Make sure that path relevant for InterSystems IRIS (usually system) contains Python installation.

3. Make sure that InterSystems IRIS can access Python installation. 

## Module not found error

Sometimes you can get module not found error. Here's how to fix it. Each step constitutes a complete solution so restart IRIS and check that the problem is fixed.

1. Check that OS bash and IRIS use the same python. Open python, execute this script from both, they should be the same. 

```
import sys
ver=sys.version
ver
``` 

If they are not the same search for a Python executable that is actually used by InterSystems IRIS.

2. Check that module is, in fact, installed. Open OS bash, execute `python` (maybe `python3` or `python36` on linux) and inside opened python bash execute `import <module>`. If it fails with some error run in OS bash `pip install <module>`. Note that module name for import and module name for pip could be different.
3. If you're sure that module is installed, compare paths used by python (it's not system path). Get path with: 
```
import sys
path=sys.path
path
```
They should be the same. If they are not the same read how `PYTHONPATH` (python) is formed [here](https://stackoverflow.com/questions/897792/where-is-pythons-sys-path-initialized-from) and adjust your OS environment to form pythonpath (python) correctly, i.e. set `PYTHONPATH` (system) env var to `C:\Users\<USER>\AppData\Roaming\Python\Python36\site-packages` or other directories where your modules reside (and other missing directories).
4. Compare python paths again and they are not the same or the problem persists add missing paths explicitly to the isc.py.ens.OutboundAdaptor init code (for interoperability) and on process start (for Callout wrapper):

```
do ##class(isc.py.Main).SimpleString("import sys")
do ##class(isc.py.Main).SimpleString("sys.path.append('C:\\Users\\<USER>\\AppData\\Roaming\\Python\\Python36\\site-packages')")
```

## `undefined symbol: _Py_TrueStruct` or similar errors

1. Check `ldconfig` and adgust it to point to the directory with Python shared library.
2. If it fails:
   - For interoperability in `isc.py.ens.Operation` operation set setting `PythonLib` to `libpython3.6m.so` or even to a full path of the shared library. 
   - For Callout wrapper on process start call `do ##class(isc.py.Callout).Initialize("libpython3.6m.so")` alternatively pass a full path of the shared library. 

## PyODBC on Linux and Mac

1. Install unixodbc: `apt-get install unixodbc-dev`
2. Install PyODBC: `pip install pyodbc`
3. Set connection string: `cnxn=pyodbc.connect(('Driver=/<IRIS directory>/bin/libirisodbcu35.so;Server=localhost;Port=51773;database=USER;UID=_SYSTEM;PWD=SYS'),autocommit=True)`

Some [notes](https://github.com/intersystems-ru/PythonAdapter/issues/50).
