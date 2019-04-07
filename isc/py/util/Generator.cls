Class isc.py.util.Generator
{

///  "wave", "aifc", "ast", "six", "pkg_resources", "hashlib", "setuptools", "astor", "botocore", "ssl"
Parameter Modules = {$lb("nyoka", "collections", "configparser", "pandas",  "csv", "dbi", "typing",  "feedparser", "chardet", "multiprocess", "tokenize", "commctrl", "win32con", "multiprocessing", "tensorflow", "Cython","odbc", "unittest", "ctypes", "parser", "numpy", "bz2file", "mimetypes", "string", "cProfile", "mmap", "stringprep", "OpenSSL", "calendar", "mmapfile", "struct", "certifi", "mmsystem", "subprocess", "cffi", "modulefinder", "sunau", "cgi", "msilib", "symbol", "cgitb", "msvcrt", "symtable", "sys", "chunk", "sysconfig", "click", "netbios", "tabnanny", "cmath", "netrc", "tarfile", "cmd", "nntplib", "telnetlib", "code", "nt", "tempfile", "codecs", "ntpath", "tensorboard", "codeop", "ntsecuritycon", "nturl2path", "termcolor", "colorama", "numbers", "test", "colorsys", "textwrap", "this", "compileall", "threading", "concurrent", "opcode", "time", "operator", "timeit", "contextlib", "optparse", "timer", "copy", "os", "tkinter", "copyreg", "pandas", "token", "pandas_ml", "cryptography", "pandocfilters", "trace",  "traceback", "pathlib", "tracemalloc", "patsy", "transmissionrpc", "cycler", "pdb", "perfmon", "turtle", "datetime", "pickle", "turtledemo", "dateutil", "pickletools", "types", "pip", "dbm", "pipes", "win32ui", "unicodedata", "dde", "decimal", "pkgutil", "urllib", "difflib", "platform", "urllib3", "dill", "plistlib", "uu", "dis", "poplib", "uuid", "distutils", "posixpath", "venv", "doctest", "pprint", "warnings", "docutils", "profile", "dummy_threading", "pstats", "weakref", "easy_install", "webbrowser", "email", "py2jdbc", "werkzeug", "encodings", "py_compile", "wheel", "ensurepip", "pyasn1", "win2kras", "enum", "pyclbr", "win32api", "errno", "pycparser", "win32clipboard", "examples", "pydoc", "win32com", "faulthandler", "pydoc_data", "pyexpat", "win32console", "filecmp", "pylab", "win32cred", "fileinput", "pyodbc", "win32crypt", "fnmatch", "pyparsing", "win32cryptcon", "formatter", "pyreadline", "win32event", "fractions", "python_jsonschema_objects", "win32evtlog", "ftplib", "pythoncom", "win32evtlogutil", "functools", "pytz", "win32file", "gast", "pywin", "win32gui", "gc", "pywin32_testutil", "win32gui_struct", "genericpath", "pywintypes", "win32help", "gensim", "pyximport", "win32inet", "getopt", "queue", "win32inetcon", "getpass", "quopri", "win32job", "gettext", "random", "win32lz", "glob", "rasutil", "win32net", "grpc", "re", "win32netcon", "gzip", "readline", "win32pdh", "h5py", "regcheck", "win32pdhquery", "regutil", "win32pdhutil", "heapq", "reprlib", "win32pipe", "hmac", "requests", "win32print", "html", "requests_negotiate_sspi", "win32process", "http", "rlcompleter", "win32profile", "idlelib", "rsa", "win32ras", "idna", "runpy", "win32rcparser", "imaplib", "s3transfer", "win32security", "imghdr", "sched", "win32service", "imp", "scipy", "win32serviceutil", "importlib", "seaborn", "win32timezone", "inflection", "secrets", "win32trace", "inspect", "select", "win32traceutil", "abc", "io", "selectors", "win32transaction", "absl", "ipaddress", "servicemanager", "win32ts", "isapi", "afxres", "itertools", "shelve", "win32uiole", "jaydebeapi", "shlex", "win32verstamp", "antigravity", "jmespath", "shutil", "win32wnet", "argparse", "json", "signal", "winerror", "array", "jsonschema", "simplejson", "winioctlcon", "asn1crypto", "keras", "site", "winnt", "keras_applications", "winperf", "keras_preprocessing", "winreg", "asynchat", "keyword", "sklearn", "winsound", "asyncio", "kiwisolver", "sklearn_pandas", "winxpgui", "asyncore", "smart_open", "winxptheme", "atexit", "lib2to3", "smtpd", "ws4py", "audioop", "linecache", "smtplib", "wsgiref", "aws_adfs", "locale", "sndhdr", "xdrlib", "awscli", "logging", "socket", "xgboost", "base64", "lxml", "socketserver", "xml", "bdb", "lzma", "sqlite3", "xmlrpc", "binascii", "macpath", "sre_compile", "xxsubtype", "binhex", "macurl2path", "sre_constants", "yaml", "bisect", "mailbox", "sre_parse", "zipapp", "boto", "mailcap", "zipfile", "boto3", "markdown", "sspi", "zipimport", "marshal", "sspicon", "zlib", "math", "stat", "builtins", "matplotlib", "statistics", "bz2", "statsmodels")};

/// do ##class(isc.py.util.Generator).Test()
ClassMethod Test(start = 1)
{
	set package = "py"
	do $system.OBJ.DeletePackage(package)
	
	set obj = ##class(isc.py.gw.Generator).%New()
	set obj.Package = package
	set obj.LogLevel = 1
	
	set startTS = $zh
	
	for i=start:1:$ll(..#Modules) {
		set sc = obj.GenerateModule($lg(..#Modules, i))
		w $System.Status.GetErrorText(sc)
		break:$$$ISERR(sc)
	}
	
	set endTS = $zh
	
	set sc = obj.Compile()
	w $System.Status.GetErrorText(sc)
	
	set compileTS = $zh
	
	break:$$$ISERR(sc)

	
	
	w $System.Status.GetErrorText(sc)
	
	do obj.DisplayWarnings()
	
	write $$$FormatText("Imported %1 modules. Generated in: %2, Compiled in: %3", $ll(..#Modules), $fnumber(endTS-startTS,"",2), $fnumber(compileTS-endTS,"",2))
	/*
	
	feedparser tensorflow - class name/attribute issue. But they compile OK.
  	
  	collection, configparser, csv
	ERROR #5475: Error compiling routine: py.collections.OrderedDict.1.  
	Errors:  ERROR: py.collections.OrderedDict.cls(fromkeys) #1010: Missing right parenthesis : 'zfromkeys(args...,iterable,value)' : Offset:18 [zfromkeys^py.collections.OrderedDict.1]
  	> ERROR #5030: An error occurred while compiling class 'py.collections.OrderedDict'
 
 	pkg_resources
 	ERROR #5001: code: zzzjson=json.dumps(zzzargs, default=zzztoserializable, allow_nan=True), variable: , serialization: 0, result:
	ERROR #5001: ['Traceback (most recent call last):
	', '  File "<string>", line 1, in <module>
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\json\__init__.py", line 238, in dumps
	    **kw).encode(obj)
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\json\encoder.py", line 199, in encode
	    chunks = self.iterencode(o, _one_shot=True)
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\json\encoder.py", line 257, in iterencode
	    return _iterencode(o, 0)
	', 'ValueError: Circular reference detected
 	
 	wave aifc
 	2019-04-04 19:47:07 Generating type: wave.Wave_write
	ERROR #5093: Name conflict on class 'py.wave.Wave.write' because package 'py.wave.wave' has the same name but differs in case.

	ast
	ERROR #5092: Name conflict on class 'py.ast.UnaryOp' because class 'py.ast.unaryop' has the same name but differs in case.
	
	hashlib
	2019-04-07 17:55:50 Generating type: _sha3.shake_256
	ERROR #5802: Datatype validation failed on property '%Dictionary.ClassDefinition:IsValid', with value equal to "py.sha3.shake.256"
  
  	setuptools
  	ERROR #5316: Class dependency loop for classes 'py.distutils.extension.Extension,py.setuptools.extension.Extension'
  	
  	six
  	2019-04-07 19:24:14 Generating type: six._MovedItems
	ERROR #5001: code: zzzmembers = zzzgetmembers(six._MovedItems, callable), variable: zzzmembers, serialization: 0, result:
	ERROR #5001: ['Traceback (most recent call last):
	', '  File "<string>", line 1, in <module>
	', '  File "<string>", line 2, in zzzgetmembers
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\inspect.py", line 342, in getmembers
	    value = getattr(object, key)
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\site-packages\six.py", line 92, in __get__
	    result = self._resolve()
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\site-packages\six.py", line 115, in _resolve
	    return _import_module(self.mod)
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\site-packages\six.py", line 82, in _import_module
	    __import__(name)
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\dbm\gnu.py", line 3, in <module>
	    from _gdbm import *
	', "ModuleNotFoundError: No module named '_gdbm'
	
	astor botocore
	ERROR #5001: code: zzzjson=json.dumps(zzzargs, default=zzztoserializable), variable: , serialization: 0, result:
	ERROR #5001: ['Traceback (most recent call last):
	', '  File "<string>", line 1, in <module>
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\json\__init__.py", line 238, in dumps
	    **kw).encode(obj)
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\json\encoder.py", line 199, in encode
	    chunks = self.iterencode(o, _one_shot=True)
	', '  File "C:\Users\eduard\AppData\Local\Programs\Python\Python36\lib\json\encoder.py", line 257, in iterencode
	    return _iterencode(o, 0)
	', 'TypeError: keys must be a string
	']
	
	ssl
	2019-04-07 19:33:17 Generating type: ssl.SSLContext
	ERROR #5001: code: import <unknown>
	
  	*/
}

ClassMethod GetArguments(type, method, ByRef arguments)
{
	set:((type="collections.OrderedDict") && (method="fromkeys")) arguments = "[[""type"", ""iterable"", ""value""], null, null, null, [], null, {}]"
}

/// based on type and method return ClassMethodValue
/// Returns one of
/// - $$$YES
/// - $$$NO
/// - "" - unknown
ClassMethod IsClassMethod(type, method) As %Boolean
{
	quit:method="__repr__" $$$NO
	quit:((type="collections.Counter") && (method="update")) $$$NO
	quit:((type="abc.ABCMeta") && ((method="__instancecheck__") || (method="__subclasscheck__"))) $$$NO
	
	quit:((type="pandas.core.arrays.base.ExtensionArray") && ((method="_concat_same_type") || (method="fillna"))) $$$NO
	quit:((type="pandas.core.series.Series") && ((method="argmax") || (method="argmin"))) $$$NO
	quit:((type="pandas.core.frame.DataFrame") && ((method="reindex") || (method="rename"))) $$$NO
	quit:((type="pandas.core.sparse.frame.SparseDataFrame") && (method="astype")) $$$YES
	quit:((type="pandas.core.sparse.series.SparseSeries") && ($lf($lb("__add__","__div__","__divmod__","__floordiv__","__floordiv__","__mod__","__mul__","__pow__","__radd__","__rdiv__","__rfloordiv__","__rmod__","__rmul__","__rpow__","__rsub__","__rsub_","__rtruediv__","__sub__","__truediv__"),method)>0)) $$$YES
	quit:((type="pandas.core.arrays.categorical.Categorical") && (method="fillna")) $$$NO
	
	quit:((type="patsy.design_info.DesignMatrix") && (method="__reduce__")) $$$NO
	
	quit:((type="weakref.WeakKeyDictionary") && (method="update")) $$$YES
	quit:((type="werkzeug.local.LocalProxy") && ($lf($lb("__delattr__","__setattr__","__str__","__eq__","__ge__","__gt__","__hash__","__le__","__lt__","__ne__"),method)>0)) $$$NO
	
	quit:((type="typing.NamedTuple") && (method="__new__")) $$$YES
	quit:((type="typing.CallableMeta") && (method="__getitem__")) $$$YES
	quit:((type="multiprocessing.context.Process") && (method="_Popen")) $$$NO
	quit:((type="multiprocess.context.Process") && (method="_Popen")) $$$NO
	quit:((type="enum.EnumMeta") && ($lf($lb("__delattr__","__setattr__","__call__"),method)>0)) $$$NO
	
	quit:((type="matplotlib.axes._base._AxesBase") && (method="draw")) $$$NO
	quit:((type="matplotlib.figure.Figure") && (method="draw")) $$$NO
	quit:((type="matplotlib.lines.Line2D") && (method="draw")) $$$NO
	quit:((type="matplotlib.text.Text") && (method="draw")) $$$NO
	quit:((type="matplotlib.patches.Patch") && (method="draw")) $$$NO
	quit:((type="matplotlib.text.Annotation") && (method="draw")) $$$NO
	
	quit:((type="fractions.Fraction") && ($lf($lb("__abs__", "__add__", "__bool__", "__ceil__", "__eq__", "__floor__", "__floordiv__", "__ge__", "__gt__", "__le__", "__lt__", "__mod__", "__mul__", "__neg__", "__pos__", "__pow__", "__radd__", "__rfloordiv__", "__rmod__", "__rmul__", "__rpow__", "__rsub__", "__rtruediv__", "__sub__", "__truediv__","__trunc__"),method)>0)) $$$NO
	
	quit:((type="h5py._hl.base.HLObject") && ($lf($lb("__eq__","__hash__","__ne__"),method))) $$$NO
	quit:((type="h5py._hl.attrs.AttributeManager") && ($lf($lb("__contains__","__getitem__","__len__"),method))) $$$NO
	
	quit:((type="sched.Event") && ($lf($lb("__eq__","__ge__","__gt__","__le__","__lt__"),method))) $$$NO
	
	quit:((type="asyncio.windows_events.ProactorEventLoop") && (method="_make_subprocess_transport")) $$$YES
	
	quit:((type="sklearn_pandas.cross_validation.GridSearchCV") && (method="predict")) $$$YES
	quit:((type="sklearn_pandas.cross_validation.RandomizedSearchCV") && (method="predict")) $$$YES
	
	quit ""
}

}

