# PythonAdapter
Python adapter via callout for InterSystems Data Platforms.

# Installation

1. Load ObjectScript code.
2. Place callout DLL/SO in `bin` folder.

## Windows 

3. Check that your `PYTHONHOME` environment variable points to Python 3.6. 
4. Check that your SYSTEM `PATH` environment variable has `PYTHONHOME` variable (or directory it points to).

## Linux 

3. Check that your SYSTEM `PATH` environment variable has `/usr/lib`, preferably at the begining

If you modified environment variables (for Windows or Linux) restart your InterSystems product.

# Use

1. Call: `do ##class(isc.py.Callout).Setup()` once per systems start (add to ZSTART: [docs](https://docs.intersystems.com/latest/csp/docbook/DocBook.UI.Page.cls?KEY=GSTU_customize#GSTU_customize_startstop), [sample](https://gist.githubusercontent.com/eduard93/412ed81e2bf619269ab4a49d939d2304/raw/c9d5f922827db5052b6e1195616d333ffe7dc1ec/%2525ZSTART)).
2. Call main method (can be called many times, context persists): `write ##class(isc.py.Callout).SimpleString(code, data)`
3. Call: `do ##class(isc.py.Callout).Finalize()` to free Python context.
4. Call: `write ##class(isc.py.Callout).Unload()` to free callout library.

```
do ##class(isc.py.Callout).Setup() 
write ##class(isc.py.Callout).SimpleString("x='ПРИВЕТ'","x")
write ##class(isc.py.Callout).SimpleString("x=repr('ПРИВЕТ')","x")
write ##class(isc.py.Callout).SimpleString("x=123","x")
do ##class(isc.py.Callout).Finalize()
write ##class(isc.py.Callout).Unload()
```

# Test Business Process

Along with callout code and Interoperability adapter there's also a test Interoperability Production and test Business Process. To use them:

1. In OS bash execute `python -m pip install  pyodbc pandas matplotlib seaborn`. 
2. Execute: `do ##class(isc.py.test.CannibalizationData).Import()` to populate test data.
3. Create ODBC connection to the namespace with data
4. In test Business Process `isc.py.test.Process` edit annotation for `Correlation Matrix: Tabular` call, specifying correct ODBC DSN in line 3
5. Edit annotation for `Correlation Matrix: Graph` call, specifying valid filepath for `f.savefig` function.
6. Save and compile business process.
7. Start `isc.py.test.Production` production.
8. Send empty `Ens.Request` mesage to the `isc.py.test.Process`.



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

1. Add Python 3.6 repo: `add-apt-repository ppa:jonathonf/python-3.6` and `apt-get update`
2. Install: `apt install python3.6 python3.6-dev libpython3.6-dev build-essential`
3. Set `GLOBALS_HOME` environment variable to the root of Caché or Ensemble installation.
4. Set environment variable `PYTHONVER` to the python version you want to build, i.e.: ` export PYTHONVER=3.6`
5. In `<Repository>/c/` execute `make`.
