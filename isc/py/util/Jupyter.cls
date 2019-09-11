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

}

