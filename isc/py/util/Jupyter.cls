/// ObjectScript part of Jupyter ContentsManager 
Class isc.py.util.Jupyter
{

Parameter DEBUG = 0;

Parameter INTERACTIVE As COSEXPRESSION = "$io[""|TRM|""";

/// Name of a SYNC activity
Parameter SYNC = "Wait for ";

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
/// w ##class(isc.py.util.Jupyter).PathToLogical()
ClassMethod PathToLogical(path As %String, isFile As %Boolean = {$$$NO}) As %String
{
	set:(isFile&&($e(path,*-5,*)=".ipynb")) path = $e(path,1,*-6)
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
	set path = ..PathToLogical(path, $$$YES)

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
	try {
		do ..Log(,"Save",path,,,,model)
		#dim sc As %Status = $$$OK
		set path = ..PathToLogical(path, $$$YES)
		//set:'##class(%Dictionary.ClassDefinition).%ExistsId(path) sc = $$$ERROR($$$GeneralError, $$$FormatText("Class %1 does not exist", path))
		set:'##class(%Dictionary.ClassDefinition).%ExistsId(path) sc = ..InitProcess(path)
		quit:$$$ISERR(sc)
		
		set model = {}.%FromJSON(model)

		set cells = [] // array with [ { Name: ActivityName1, Annotation: ActivityAnnotation1}, ... ] structure 
		set names = "" // %List with $lb(ActivityName1, ActivityName2, ..., ActivityNameN) structure
		set iterator = model.content.cells.%GetIterator()
		while iterator.%GetNext(.key, .value) {
			if value."cell_type" = "markdown" {
				set name = $e(value.source, 3, *)
				do iterator.%GetNext(.key, .value)
				if value."cell_type" = "code" {
					do cells.%Push({"Name":(name), "Annotation":($replace(value.source, $c(10), $$$NL))})
					set names = names _ $lb(name)
				}
			}
		}

		set sc = ..UpdateBPL(path, cells, names)
		quit:$$$ISERR(sc) //sc

		set sc = $system.OBJ.Compile(path, "/displaylog=0 /displayerror=0")
	} catch ex {
		do ex.Log()
		set sc =ex.AsStatus()
	}
	quit sc
}

/// Does the item exists
ClassMethod Exists(path) As %Boolean
{
	set path = ..PathToLogical(path)
	set exists = ##class(%Dictionary.ClassDefinition).%ExistsId(path)
	do ..Log(,"Exists",path,exists)
	quit exists
}

/// w ##class(isc.py.util.Jupyter).PackageExists("isc")
ClassMethod PackageExists(package) As %Boolean
{
    set prefix = package_"."
    set firstClass = $o(^oddCOM(prefix))
    quit prefix = $e(firstClass,1,$l(prefix))
}

/// w ##class(isc.py.util.Jupyter).Delete()
ClassMethod Delete(path) As %Boolean
{
	#dim sc As %Status = $$$OK
	set path = ..PathToLogical(path)
	do ..Log(,"Delete", path)
	
	set rs = ##class(isc.py.util.Jupyter).GetBPLFunc(path)
	
	while rs.%Next() {
		set sc1 = ##class(%Dictionary.ClassDefinition).%DeleteId(rs.Name)
		set sc = $$$ADDSC(sc, sc1)
	}
	
	quit $$$ISOK(sc)
}

/// w ##class(isc.py.util.Jupyter).Rename("User.A","User.B")
ClassMethod Rename(oldPath, newPath) As %Boolean
{
	#dim sc As %Status = $$$OK
	set oldPath = ..PathToLogical(oldPath)
	set newPath = ..PathToLogical(newPath)
	do ..Log(,"Rename", oldPath, newPath)
	
	quit:'##class(%Dictionary.ClassDefinition).%ExistsId(oldPath) $$$NO // Old class does not exist
	quit:##class(%Dictionary.ClassDefinition).%ExistsId(newPath) $$$YES // New class already exists
	
	merge ^oddDEF(newPath) = ^oddDEF(oldPath)
	$$$defClassKeySet(newPath, $$$cCLASSname, newPath) // Set class name
	$$$defClassKeyKill(newPath, $$$cCLASSstorage) // Kill old storage
	
	Do UpdClsDef^%occLibrary(newPath)
	
	set sc = $system.OBJ.Compile(newPath, "/displaylog=0 /displayerror=0")
	set:$$$ISOK(sc) sc = ##class(%Dictionary.ClassDefinition).%DeleteId(oldPath)
	
	quit $$$ISOK(sc)
}

/// Does the item exists
/// w ##class(isc.py.util.Jupyter).ExistsDir()
ClassMethod ExistsDir(path) As %Boolean
{
	set path = ..PathToLogical(path)

	#dim exists As %Boolean
	if path = "" {
		set exists = $$$YES
	} else {
		set exists = ..PackageExists(path)
	}	

	do ..Log(,"ExistsDir",path,exists)
	quit exists
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
			if ..IsJupyterActivity(activity) {
				do cells.%Push(..GetNameCell(activity.Name))				
				do cells.%Push(..GetCodeCell(annotationText))
			}
		}
	}
	
	quit cells
}

/// Update BPL from JSON
ClassMethod UpdateBPL(class, cells As %DynamicArray, names As %List) As %Status [ PublicList = cells ]
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
			set iterator = cells.%GetIterator()
			do ..UpdateActivities(activities, iterator, names)
			
			// Append end cells if any
			#dim iterator As %Iterator.Array
			while iterator.%GetNext(.key,.cell) {
				do activities.Insert(..GenerateActivity(cell.Name, cell.Annotation))
				do activities.Insert(..GeterateSync(cell.Name))
			}
			
			do stream.Rewind()
			set sc = process.GenerateXML(stream)
			quit:$$$ISERR(sc)
			
			set sc = xData.%Save()
	    }
	} catch ex {
		do ex.Log()
	    set sc = ex.AsStatus()
	}
	quit sc
}

/// Update individual activities from JSON
ClassMethod UpdateActivities(activities As Ens.BPL.ActivityList, iterator As %Iterator.Array, names As %List)
{
	try {
		quit:'$isObject($g(iterator))
		for i=1:1:activities.Count() {
			#dim activity As Ens.BPL.Activity
			set activity = activities.GetAt(i)
			quit:'$isObject(activity)
			
			set class = activity.%ClassName(1)
			if $lf(##class(isc.py.ens.ProcessUtils).#ActivityNodes, class) {
				do ..UpdateActivities(activity.Activities, iterator, names)
			} elseif (class="Ens.BPL.If") {
				do ..UpdateActivities(activity.True, iterator, names)
				do ..UpdateActivities(activity.False, iterator, names)
			} elseif (class ="Ens.BPL.Switch"){
				do ..UpdateActivities(activity.Cases, iterator, names)
			} else {
				if ..IsJupyterActivity(activity) {
					if $lf(names, activity.Name) {
						// Activity is down the line
						
						// cell - object with { Name: ActivityName, Annotation: ActivityAnnotation} structure 
						do iterator.%GetNext(.key,.cell)
						
						// Add cells till we get to our cell
						while (cell.Name '= activity.Name) {
							// Add new cells to BP

							do activities.InsertAt(..GeterateSync(cell.Name), i)
							do activities.InsertAt(..GenerateActivity(cell.Name, cell.Annotation), i)
							do iterator.%GetNext(.key,.cell)
						}

						// We iterated to the right activity
						set activity.Annotation = cell.Annotation
					} else {
						// Delete BP activities
						do activities.RemoveAt(i)
						do:(activities.GetAt(i).Name=(..#SYNC_activity.Name)) activities.RemoveAt(i)
					}
				}
			}
		}	
	} catch ex {
		do ex.Log()
		break:..#INTERACTIVE
		throw ex
	}
}

ClassMethod GenerateActivity(name, code) As Ens.BPL.Call
{
	/*
	<call name='Import pandas' target='@..%Process.PythonOperation' async='1' >
	<annotation><![CDATA[import pandas as pd

	import sys]]></annotation>
	<request type='isc.py.msg.ExecutionRequest' >
	<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Import pandas&quot;)" action="set" />
	</request>
	<response type='isc.py.msg.ExecutionResponse' />
	</call>
	
	<sync name='Wait for import' calls='Import pandas' type='all' xpos='200' ypos='350' />
	*/
	set activity = ##class(Ens.BPL.Call).%New()
	set activity.Name = name
	set activity.Target = "@..%Process.PythonOperation"
	set activity.Async = $$$YES
	set activity.Annotation = code
	
	set request = ##class(Ens.BPL.Request).%New()
	set request.Type = "isc.py.msg.ExecutionRequest"
	set activity.Request = request
	
	set assign = ##class(Ens.BPL.Assign).%New()
	set assign.Property = "callrequest.Code"
	set assign.Value = "process.GetAnnotation(""" _ name _ """)"
	do request.Activities.Insert(assign)
	
	set response = ##class(Ens.BPL.Response).%New()
	set response.Type = "isc.py.msg.ExecutionResponse"
	set activity.Response = response
	
	quit activity
}

ClassMethod GeterateSync(name As %String) As Ens.BPL.Sync
{
	set sync = ##class(Ens.BPL.Sync).%New()
	set sync.Calls = name
	set sync.Name = ..#SYNC _ name
	quit sync
}

ClassMethod IsJupyterActivity(activity As Ens.BPL.Activity) As %Boolean [ CodeMode = expression ]
{
activity.Annotation'=""
}

ClassMethod GetNameCell(name) [ CodeMode = expression ]
{
{
	"cell_type": "markdown",
	"metadata": {"editable": true},
	"source": ("# " _ name)
}
}

ClassMethod GetCodeCell(value) [ CodeMode = expression ]
{
{
   "cell_type": "code",
   "metadata": {},
   "outputs": [],
   "execution_count": 0,
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

/// Create default Python-enabled business process.
/// w $System.Status.GetErrorText(##class(isc.py.util.Jupyter).InitProcess("Test.MyBP"))
ClassMethod InitProcess(class) As %Status
{
	#dim sc As %Status = $$$OK
	quit:##class(%Dictionary.ClassDefinition).%ExistsId(class) $$$ERROR($$$GeneralError, $$$FormatText("Class %1 already exists", class))
	set sc = ##class(%Dictionary.CacheClassname).IsValid(class) 
	quit:$$$ISERR(sc) $$$ADDSC($$$ERROR($$$GeneralError, $$$FormatText("Class name %1 is invalid", class)), sc)
	
	set bp = ##class(%Dictionary.ClassDefinition).%New(class, $$$CLASSDEFINITIONVERSION)
	
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

/// Interactively installs Iris Native API for Python and Jupyter Notebook
/// do ##class(isc.py.util.Jupyter).Install()
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

/// Create Jupyter config to use with InterSystems IRIS
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

/// Check if module is installed and install it if needed.
/// module - module name. 
/// source - if provided (can be a URI or file path) it would be used instead of module name to install the module
/// verbose - hints in case autoinstallation fails.
/// do ##class(isc.py.util.Jupyter).ModuleCheck()
ClassMethod ModuleCheck(module, source, verbose As %Boolean = {$$$NO}) As %Status
{
	#dim sc As %Status = $$$OK
	write:verbose "Checking ", module,!
	
	set cmd = "pip3"
	set timeout = 60
	
	set args = 2
	set args(1) = "show"
	set args(2) = module
	set sc = ##class(%Net.Remote.Utility).RunCommandViaZF(cmd, , .out, timeout, $$$YES, .code, .args)
	
	quit:$$$ISERR(sc) $$$ADDSC($$$ERROR($$$GeneralError, "Unable to detect ", module), sc)
		
	
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
			set sc = $$$ADDSC($$$ERROR($$$GeneralError, "Unable to install ", module), sc)
		} else {
			write:verbose "Suceessfully installed ", module
		}	
	}
	quit sc
}

ClassMethod GetNativeWheel() As %String
{
	set dir = ##class(%File).SubDirectoryName(##class(%File).SubDirectoryName($System.Util.InstallDirectory(), "dev"), "python", 1)
	set file = $zsearch(dir _ "irisnative-*cp3*.whl")
	set:file="" file = $zsearch(dir _ "*py3*.whl")
	quit file
}

/// Debug info
ClassMethod Log(class = {$classname()}, method, path = "", content = "", type = "", format = "", model = "") As %Status
{
	quit:'..#DEBUG $$$OK
	quit:..#INTERACTIVE $$$OK
	quit $$$OK
	//quit ##class(User.Logger).Log(class, method, path, content, type, format, model)
}

}

