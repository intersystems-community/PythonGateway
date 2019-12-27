/// ObjectScript part of Jupyter ContentsManager 
Class isc.py.util.Jupyter
{

/// do ##class(isc.py.util.Jupyter).GetBPLFunc("").%Display()
Query GetBPL(path) As %SQLQuery
{
SELECT DISTINCT 
	CASE nvl(:path,'')
	WHEN '' THEN $PIECE(Name, '.')
	ELSE $PIECE(Name, '.', 1, $LENGTH(:path, '.') + 1) END Name
FROM %Dictionary.ClassDefinitionQuery_SubclassOf('Ens.BusinessProcessBPL')
WHERE Name %STARTSWITH :path
}

/// Translate Jupyter Path into InterSystems IRIS path
ClassMethod PathToLogical(path As %String) As %String
{
	
	set path = $tr(path, "/" _ $c(0), ".")
	set:$e(path)="." path = $e(path, 2, *)
	set:$e(path,*,*)="." path = $e(path, 1, *-1)
	quit path
}

/// Serve directory on notebook
/// path - path to serve
/// content - return contents or not
/// type - expected type of returned element
/// format - return format. Always JSON
/// w ##class(isc.py.util.Jupyter).Get()
ClassMethod Get(path As %String, content As %Boolean, type, format) As %String
{
	set path = ..PathToLogical(path)

	set obj = ..Node(path)
	
	if ##class(%Dictionary.ClassDefinition).%ExistsId(path) {
		if content=$$$YES {
			set obj.content = ..GetBPLContent(path)
		} else {
			do obj.%Set("content", "", "null")
			do obj.%Set("format", "", "null")
		}
		set obj.type = "notebook"
		set obj.size = 1000
	} else {
		set rs = ..GetBPLFunc(path)
		while rs.%Next() {
			set node = ..Node(rs.Name)
			do node.%Set("content", "", "null")
			do obj.content.%Push(node)	
		}
	}
	
	quit obj.%ToJSON()
}

/// Save notebook as BPL. Updates existing activities.
/// w ##class(isc.py.util.Jupyter).Save()
ClassMethod Save(model, path) As %String
{
	#dim sc As %Status = $$$OK
	set path = ..PathToLogical(path)
	quit:'##class(%Dictionary.ClassDefinition).%ExistsId(path) $$$ERROR($$$GeneralError, $$$FormatText("Class %1 does not exist", path))
	
	set model = {}.%FromJSON(model)

	set cells = {} // object with { ActivityName1: ActivityAnnotation1, ... } structure 
	set iterator = model.content.cells.%GetIterator()
	while iterator.%GetNext(.key, .value) {
		if value."cell_type" = "markdown" {
			set name = $e(value.source, 3, *)
			do iterator.%GetNext(.key, .value)
			if value."cell_type" = "code" {
				do cells.%Set(name, $replace(value.source, $c(10), $$$NL))
			}
		}
	}
	
	set sc = ..UpdateBPL(path, cells)
	quit:$$$ISERR(sc) sc

	set sc = $system.OBJ.Compile(path, "/displaylog=0 /displayerror=0")
	quit sc
}

/// Translate BPL into JSON
ClassMethod GetBPLContent(class) As %DynamicObject
{
	set obj = ..BPLContentsBase()
		
	set sc = $$$OK
	try {
	    #; Don't run this method on the base class
	    quit:##class(%Dictionary.CompiledXData).%ExistsId(class_"||BPLERROR")
	    
	    #; find XDATA block named BPL
	    if ##class(%Dictionary.CompiledXData).%ExistsId(class_"||BPL") {
    
	        #; Get XDATA as stream
	        set stream = ##class(%Dictionary.CompiledXData).%OpenId(class_"||BPL").Data
	        do stream.Rewind()

	        set parser=##class(Ens.BPL.Parser).%New()
	    
	        #; Parse the specified stream and obtain the root of the parse tree,
	        #; Ens.BPL.Process
	        #dim process As Ens.BPL.Process
			set sc = parser.ParseStream(stream,.process)
			quit:$$$ISERR(sc)
			
			#dim activities As Ens.BPL.ActivityList
			set activities = process.Sequence.Activities
			set obj.cells = ..ParseActivities(activities)	

	    }
	} catch ex {
	    set sc = ex.AsStatus()
	}
	quit obj
}

/// Translate individual activities into JSON
ClassMethod ParseActivities(activities As Ens.BPL.ActivityList, ByRef cells As %DynamicObject) As %DynamicObject
{
	set:'$isObject($g(cells)) cells = []
	for i=1:1:activities.Count() {
		#dim activity As Ens.BPL.Activity
		set activity = activities.GetAt(i)
		set class = activity.%ClassName(1)
		if $lf(##class(isc.py.ens.ProcessUtils).#ActivityNodes, class) {
			do ..ParseActivities(activity.Activities, cells)
		} elseif (class="Ens.BPL.If") {
			do ..ParseActivities(activity.True, cells)
			do ..ParseActivities(activity.False, cells)
		} elseif (class ="Ens.BPL.Switch"){
			do ..ParseActivities(activity.Cases, cells)
		} else {
			set annotationText = activity.Annotation
			//set annotationText = $$$quote(activity.Annotation)
			if activity.Annotation'="" {
				do cells.%Push(..GetNameCell(activity.Name))				
				do cells.%Push(..GetCodeCell(annotationText))
			}
		}
	}
	
	quit cells
}

/// Update BPL from JSON
ClassMethod UpdateBPL(class, cells As %DynamicObject) As %Status
{
	set sc = $$$OK
	try {
	    #; Don't run this method errored BP
	    quit:##class(%Dictionary.XDataDefinition).%ExistsId(class_"||BPLERROR")
	    
	    #; find XDATA block named BPL
	    if ##class(%Dictionary.XDataDefinition).%ExistsId(class_"||BPL") {
    
	        #; Get XDATA as stream
	        set xData = ##class(%Dictionary.XDataDefinition).%OpenId(class_"||BPL")
	        set stream = xData.Data
	        do stream.Rewind()

	        set parser=##class(Ens.BPL.Parser).%New()
	    
	        #; Parse the specified stream and obtain the root of the parse tree,
	        #; Ens.BPL.Process
	        #dim process As Ens.BPL.Process
			set sc = parser.ParseStream(stream,.process)
			quit:$$$ISERR(sc)
			
			#dim activities As Ens.BPL.ActivityList
			set activities = process.Sequence.Activities
			do ..UpdateActivities(activities, cells)
			
			do stream.Rewind()
			set sc = process.GenerateXML(stream)
			quit:$$$ISERR(sc)
			
			set sc = xData.%Save()
	    }
	} catch ex {
	    set sc = ex.AsStatus()
	}
	quit sc
}

/// Update individual activities from JSON
ClassMethod UpdateActivities(activities As Ens.BPL.ActivityList, cells As %DynamicObject)
{
	quit:'$isObject($g(cells))
	for i=1:1:activities.Count() {
		#dim activity As Ens.BPL.Activity
		set activity = activities.GetAt(i)
		set class = activity.%ClassName(1)
		if $lf(##class(isc.py.ens.ProcessUtils).#ActivityNodes, class) {
			do ..UpdateActivities(activity.Activities, cells)
		} elseif (class="Ens.BPL.If") {
			do ..UpdateActivities(activity.True, cells)
			do ..UpdateActivities(activity.False, cells)
		} elseif (class ="Ens.BPL.Switch"){
			do ..UpdateActivities(activity.Cases, cells)
		} else {
			if cells.%IsDefined(activity.Name) {
				set activity.Annotation = cells.%Get(activity.Name)
			}
		}
	}
}

ClassMethod GetNameCell(name) [ CodeMode = expression ]
{
{
	"cell_type": "markdown",
	"metadata": {"editable": false},
	"source": ("# " _ name)
}
}

ClassMethod GetCodeCell(value) [ CodeMode = expression ]
{
{
   "cell_type": "code",
   "metadata": {},
   "outputs": [],
   "source": (value)
 }
}

ClassMethod BPLContentsBase() As %DynamicObject [ CodeMode = expression ]
{
{
	"cells": [],
	"metadata": {
		"kernelspec": {
			"display_name": "Python 3",
			"language": "python",
			"name": "python3"
		},
		"language_info": {
			"codemirror_mode": {
				"name": "ipython",
				"version": 3
		},
		"file_extension": ".py",
		"mimetype": "text/x-python",
		"name": "python",
		"nbconvert_exporter": "python",
		"pygments_lexer": "ipython3",
		"version": "3.6.7"
		}
	},
	"nbformat": 4,
	"nbformat_minor": 2
}
}

/// Get model node
ClassMethod Node(path) [ CodeMode = expression ]
{
{
   "name":($p(path, ".", *)),
   "path": ($tr(path, ".", "/")),
   "last_modified":(..GetLastModified(path)),
   "created":null,
   "content":[],
   "format":"json",
   "mimetype":null,
   "size":null,
   "writable":true,
   "type":($case(path="", $$$YES:"directory", :$case(##class(%Dictionary.ClassDefinition).%ExistsId(path), $$$YES:"notebook", $$$NO:"directory")))
}
}

/// Get Last Modified Time for a path
ClassMethod GetLastModified(path As %String)
{
	if ((path'="") && (##class(%Dictionary.ClassDefinition).%ExistsId(path))) {
		set time = $$$defClassKeyGet(path,$$$cCLASStimechanged)
	} else {
		set time = $h
		&sql(SELECT max(c.TimeChanged) INTO :time
			 FROM %Dictionary.ClassDefinitionQuery_SubclassOf('Ens.BusinessProcessBPL') q
			 JOIN %Dictionary.ClassDefinition c ON c.Name = q.Name
			 WHERE q.Name %STARTSWITH :path)
	}
	
	quit $tr($zdt(time, 3, 1, 3), " ", "T")
}

/// Simple BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.Request' response='Ens.Response'>
<sequence >
</sequence>
</process>
}

/// w $System.Status.GetErrorText(##class(isc.py.util.Jupyter).InitProcess("Test.MyBP"))
ClassMethod InitProcess(class) As %Status
{
	#dim sc As %Status = $$$OK
	quit:##class(%Dictionary.ClassDefinition).%ExistsId(class) $$$ERROR($$$GeneralError, $$$FormatText("Class %1 already exists", class))
	set sc = ##class(%Dictionary.CacheClassname).IsValid(class) 
	quit:$$$ISERR(sc) $$$ADDSC($$$ERROR($$$GeneralError, $$$FormatText("Class name %1 is invalid", class)), sc)
	
	set bp = ##class(%Dictionary.ClassDefinition).%New(class, 25)
	
	set utils = "isc.py.ens.ProcessUtils"	
	set bp.Super = "Ens.BusinessProcessBPL, " _ utils
	set bp.DependsOn = utils
	
	set pythonOp = ##class(%Dictionary.PropertyDefinition).%New()
	set pythonOp.parent = bp
	set pythonOp.Name = "PythonOperation"
	set pythonOp.InitialExpression = """isc.py.ens.Operation"""
	do pythonOp.Parameters.SetAt(128, "MAXLEN")

	set settingsParam = ##class(%Dictionary.ParameterDefinition).%New()
	set settingsParam.parent = bp
	set settingsParam.Name = "SETTINGS"
	set settingsParam.Default = "PythonOperation:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}"
	
	set bplDataTemplate = ##class(%Dictionary.XDataDefinition).IDKEYOpen($classname(), "BPL")
	#dim bplData As %Dictionary.XDataDefinition
	set bplData = bplDataTemplate.%ConstructClone()
	set bplData.parent = bp

	set sc = bp.%Save()
	quit:$$$ISERR(sc) sc
	
	set sc = $system.OBJ.Compile(class, "/displaylog=0 /displayerror=0")
	
	quit sc
}

/// w $System.Status.GetErrorText(##class(isc.py.util.Jupyter).Install())
ClassMethod Install()
{
	
	set version = $system.Version.GetNumber()
	set minVersion = 2019.3
	if version<minVersion {
		write $$$FormatText("Current version %1 is lesser than minimal version %2. Exiting.", version, minVersion)
		quit
	}

	set sc = ..ModuleCheck("irisnative", ..GetNativeWheel(), $$$YES)
	if $$$ISERR(sc) {
		write $System.Status.GetErrorText(sc)
		quit
	}
	
	set sc = ..ModuleCheck("jupyter", , $$$YES)
	if $$$ISERR(sc) {
		write $System.Status.GetErrorText(sc)
		quit
	}

	write "Enter values (press Enter if the default value is OK)"

	set sc = ##class(%RoutineMgr).GetWebServerPort(,.host)
	set sc = ##class(%Prompt).GetString("Host:", .host)

	set port = $get(^%SYS("SSPort"), 51773)
	set sc = ##class(%Prompt).GetNumber("Port:", .port)

	set namespace = $namespace
	set sc = ##class(%Prompt).GetString("Namespace:", .namespace)

	set user = $username
	set sc = ##class(%Prompt).GetString("User:", .user, 1, 160)

	set sc = ##class(%Prompt).GetString("Password:", .password, 1)

	set dirMsg = "Directory (for config file, it MUST contain MLContentsManager.py and usually is <PythonGateway\Jupyter\>):" 
	set sc = ##class(%Prompt).GetString(dirMsg, .directory)

	set sc = ..CreateConfig(host, port, namespace, user, password, directory)

	if $$$ISERR(sc) {
		write "Error creating config: ", $System.Status.GetErrorText(sc)
		quit
	}

	write !,!
	write "Success", !
	write "Too start open '", directory, "' directory in command line and type:", !
	write $c(27)_"[1mjupyter notebook"_$c(27)_"[0m", !
}

/// d ##class(isc.py.util.Jupyter).CreateConfig()
ClassMethod CreateConfig(host, port = {$get(^%SYS("SSPort"), 51773)}, namespace = {$namespace}, user = {$username}, password, directory) As %Status
{
  #dim sc As %Status = $$$OK
  set:'$d(host) sc = ##class(%RoutineMgr).GetWebServerPort(,.host)
  quit:$$$ISERR(sc) sc
  
  quit:'$d(directory) $$$ERROR($$$GeneralError, "Directory must be set and contain MLContentsManager.py")
  set directory = ##class(%File).NormalizeDirectory(directory)
  
  
  set file = ##class(%Stream.FileCharacter).%New()
  do file.LinkToFile(directory _ "jupyter_notebook_config.py")
  
  do file.WriteLine("exec(open(""MLContentsManager.py"").read())")
  do file.WriteLine("c.NotebookApp.contents_manager_class = MLContentsManager")
  
  do file.WriteLine("c.MLContentsManager.host = '" _ host _ "'")
  do file.WriteLine("c.MLContentsManager.port = " _ port)
  do file.WriteLine("c.MLContentsManager.namespace = '"_ namespace _ "'")
  do file.WriteLine("c.MLContentsManager.user = '"_ user _ "'")
  do file.WriteLine("c.MLContentsManager.password = '"_ password _ "'")
  
  set sc = file.%Save()
  quit sc
}

/// d ##class(isc.py.util.Jupyter).ModuleCheck()
ClassMethod ModuleCheck(module, source, verbose As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	write:verbose "Checking ", module,!
	
	set cmd = "pip"
	set timeout = 60
	
	set args = 2
	set args(1) = "show"
	set args(2) = module
	set sc = ##class(%Net.Remote.Utility).RunCommandViaZF(cmd, , .out, timeout, $$$YES, .code, .args)
	
	quit:$$$ISERR(sc) $$$ADDSC($$$ERROR($$$GeneralError, "Unable to detect ", module, ", aborting"), sc)
		
	
	if out'="" {
		write:verbose module, " is installed", !
	} else {
		write:verbose module, " is NOT found. Attempting install", !

		kill args, out, code
		set args = 2
		set args(1) = "install"
		set args(2) = $case($d(source), $$$YES: source, :module)
		set sc = ##class(%Net.Remote.Utility).RunCommandViaZF(cmd, , .out, timeout, $$$YES, .code, .args)
		if $$$ISERR(sc) {
			write:verbose "Auto install failed, try running: ", cmd, " ", args(1), " ", args(2), !
			set sc = $$$ADDSC($$$ERROR($$$GeneralError, "Unable to install ", module, ", aborting"), sc)
		} else {
			write:verbose "Suceessfully installed ", module
		}	
	}
	quit sc
}

ClassMethod GetNativeWheel() As %String
{
	set dir = ##class(%File).SubDirectoryName(##class(%File).SubDirectoryName($System.Util.InstallDirectory(), "dev"), "python", 1)
	set file = $zsearch(dir _ "irisnative-*cp36*.whl")
	quit file
}

}

