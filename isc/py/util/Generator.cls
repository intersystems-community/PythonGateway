/// Various utilities for class generator
Class isc.py.util.Generator
{

/// List of modules to import
///  "wave", "aifc", "ast", "six","hashlib", "setuptools", 
Parameter Modules = {$lb( "pkg_resources", "astor", "botocore", "ssl", "nyoka", "collections", "configparser", "pandas",  "csv", "dbi", "typing",  "feedparser", "chardet", "multiprocess", "tokenize", "commctrl", "win32con", "multiprocessing", "tensorflow", "Cython","odbc", "unittest", "ctypes", "parser", "numpy", "bz2file", "mimetypes", "string", "cProfile", "mmap", "stringprep", "OpenSSL", "calendar", "mmapfile", "struct", "certifi", "mmsystem", "subprocess", "cffi", "modulefinder", "sunau", "cgi", "msilib", "symbol", "cgitb", "msvcrt", "symtable", "sys", "chunk", "sysconfig", "click", "netbios", "tabnanny", "cmath", "netrc", "tarfile", "cmd", "nntplib", "telnetlib", "code", "nt", "tempfile", "codecs", "ntpath", "tensorboard", "codeop", "ntsecuritycon", "nturl2path", "termcolor", "colorama", "numbers", "test", "colorsys", "textwrap", "this", "compileall", "threading", "concurrent", "opcode", "time", "operator", "timeit", "contextlib", "optparse", "timer", "copy", "os", "tkinter", "copyreg", "pandas", "token", "pandas_ml", "cryptography", "pandocfilters", "trace",  "traceback", "pathlib", "tracemalloc", "patsy", "transmissionrpc", "cycler", "pdb", "perfmon", "turtle", "datetime", "pickle", "turtledemo", "dateutil", "pickletools", "types", "pip", "dbm", "pipes", "win32ui", "unicodedata", "dde", "decimal", "pkgutil", "urllib", "difflib", "platform", "urllib3", "dill", "plistlib", "uu", "dis", "poplib", "uuid", "distutils", "posixpath", "venv", "doctest", "pprint", "warnings", "docutils", "profile", "dummy_threading", "pstats", "weakref", "easy_install", "webbrowser", "email", "py2jdbc", "werkzeug", "encodings", "py_compile", "wheel", "ensurepip", "pyasn1", "win2kras", "enum", "pyclbr", "win32api", "errno", "pycparser", "win32clipboard", "examples", "pydoc", "win32com", "faulthandler", "pydoc_data", "pyexpat", "win32console", "filecmp", "pylab", "win32cred", "fileinput", "pyodbc", "win32crypt", "fnmatch", "pyparsing", "win32cryptcon", "formatter", "pyreadline", "win32event", "fractions", "python_jsonschema_objects", "win32evtlog", "ftplib", "pythoncom", "win32evtlogutil", "functools", "pytz", "win32file", "gast", "pywin", "win32gui", "gc", "pywin32_testutil", "win32gui_struct", "genericpath", "pywintypes", "win32help", "gensim", "pyximport", "win32inet", "getopt", "queue", "win32inetcon", "getpass", "quopri", "win32job", "gettext", "random", "win32lz", "glob", "rasutil", "win32net", "grpc", "re", "win32netcon", "gzip", "readline", "win32pdh", "h5py", "regcheck", "win32pdhquery", "regutil", "win32pdhutil", "heapq", "reprlib", "win32pipe", "hmac", "requests", "win32print", "html", "requests_negotiate_sspi", "win32process", "http", "rlcompleter", "win32profile", "idlelib", "rsa", "win32ras", "idna", "runpy", "win32rcparser", "imaplib", "s3transfer", "win32security", "imghdr", "sched", "win32service", "imp", "scipy", "win32serviceutil", "importlib", "seaborn", "win32timezone", "inflection", "secrets", "win32trace", "inspect", "select", "win32traceutil", "abc", "io", "selectors", "win32transaction", "absl", "ipaddress", "servicemanager", "win32ts", "isapi", "afxres", "itertools", "shelve", "win32uiole", "jaydebeapi", "shlex", "win32verstamp", "antigravity", "jmespath", "shutil", "win32wnet", "argparse", "json", "signal", "winerror", "array", "jsonschema", "simplejson", "winioctlcon", "asn1crypto", "keras", "site", "winnt", "keras_applications", "winperf", "keras_preprocessing", "winreg", "asynchat", "keyword", "sklearn", "winsound", "asyncio", "kiwisolver", "sklearn_pandas", "winxpgui", "asyncore", "smart_open", "winxptheme", "atexit", "lib2to3", "smtpd", "ws4py", "audioop", "linecache", "smtplib", "wsgiref", "aws_adfs", "locale", "sndhdr", "xdrlib", "awscli", "logging", "socket", "xgboost", "base64", "lxml", "socketserver", "xml", "bdb", "lzma", "sqlite3", "xmlrpc", "binascii", "macpath", "sre_compile", "xxsubtype", "binhex", "macurl2path", "sre_constants", "yaml", "bisect", "mailbox", "sre_parse", "zipapp", "boto", "mailcap", "zipfile", "boto3", "markdown", "sspi", "zipimport", "marshal", "sspicon", "zlib", "math", "stat", "builtins", "matplotlib", "statistics", "bz2", "statsmodels")};

/// Import all modules. Breaks on error
/// do ##class(isc.py.util.Generator).Test()
ClassMethod Test(start = 1)
{
	set obj = ##class(isc.py.gw.Generator).%New()
	do $system.OBJ.DeletePackage(obj.Package)
	set obj.LogLevel = 1
	
	set startTS = $zh
	
	for i=start:1:$ll(..#Modules) {
		set sc = obj.GenerateModule($lg(..#Modules, i))
		w $System.Status.GetErrorText(sc)
		break:$$$ISERR(sc)
	}
	
	set endTS = $zh
	
	set sc = obj.Compile()
	write $System.Status.GetErrorText(sc)
	
	set compileTS = $zh
	
	break:$$$ISERR(sc)

	write $System.Status.GetErrorText(sc)
	
	do obj.DisplayWarnings()
	
	write $$$FormatText("Imported %1 modules. Generated in: %2, Compiled in: %3", $ll(..#Modules), $fnumber(endTS-startTS,"",2), $fnumber(compileTS-endTS,"",2))
}

/// Sample call of gateway imported module 'ed'.
/// do ##class(isc.py.util.Generator).Test2()
ClassMethod Test2() As %Status [ PublicList = r ]
{
	if '$d(r) {
		set r = ##class(isc.py.util.Redirect).%New()
		do r.Init()
		do r.Enable(1)
	}
	
	set sc = ##class(isc.py.Main).ImportModule("ed")
	quit:$$$ISERR(sc) sc
	
	
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
	
	zw sc
	w r.GetString()
	
	
	quit sc
}

/// Fix arguments value.
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
	
	quit:((type="pkg_resources.MemoizedZipManifests") && (method="load")) $$$YES
	
	quit ""
}

}

