/// Utilities for Python PB
Class isc.py.ens.ProcessUtils
{

/// List of nodes that may contain ActivityList.
/// Retrieved with:
/// SELECT  parent, ID,  Name, Type
/// FROM %Dictionary.CompiledProperty
/// WHERE Parent %STARTSWITH 'Ens.BPL' AND Name='Activities'
Parameter ActivityNodes = {$lb("Ens.BPL.Case", "Ens.BPL.CaseNode", "Ens.BPL.Catch", "Ens.BPL.CatchAll", "Ens.BPL.CompensationHandler", "Ens.BPL.Default", "Ens.BPL.Flow", "Ens.BPL.ForEach", "Ens.BPL.Message", "Ens.BPL.Request", "Ens.BPL.Response", "Ens.BPL.Scope", "Ens.BPL.Sequence", "Ens.BPL.Until", "Ens.BPL.While")};

/// Get value of activity annatation by name
ClassMethod GetAnnotation(name As %String) As %String [ CodeMode = objectgenerator ]
{
    set sc = $$$OK
    try {
        #; Don't run this method on the base class
        quit:%compiledclass.Name="isc.py.ens.AbstractBPLProcess"  
        quit:##class(%Dictionary.CompiledXData).%ExistsId(%class.Name_"||BPLERROR")
        
        #; find XDATA block named BPL
        if ##class(%Dictionary.CompiledXData).%ExistsId(%class.Name_"||BPL") {
            set index = %compiledclass.XDatas.FindObjectId(%class.Name_"||BPL")
        
            #; get XDATA as stream
            set stream = %compiledclass.XDatas.GetAt(index).Data
            do stream.Rewind()
    
            set parser=##class(Ens.BPL.Parser).%New()
        
	        #; Parse the specified stream and obtain the root of the parse tree,
	        #; Ens.BPL.Process
	        #dim process As Ens.BPL.Process
			set sc = parser.ParseStream(stream,.process)
			quit:$$$ISERR(sc)
			
			#dim activities As Ens.BPL.ActivityList
			set activities = process.Sequence.Activities
			do ..ParseActivities(activities)	

			do %code.WriteLine(" quit """"")
        }
    } catch ex {
	    set sc = ex.AsStatus()
    }
    quit sc
}

/// Get value of activity annatation by name as stream
ClassMethod GetAnnotationStream(name As %String) As %Stream.GlobalCharacter
{
	set stream = ##class(%Stream.GlobalCharacter).%New()
	do stream.Write(..GetAnnotation(name))
	quit stream
}

ClassMethod ParseActivities(activities As Ens.BPL.ActivityList)
{
	for i=1:1:activities.Count() {
		#dim activity As Ens.BPL.Activity
		set activity = activities.GetAt(i)
		set class = activity.%ClassName(1)
		if $lf(..#ActivityNodes, class) {
			do ..ParseActivities(activity.Activities)
		} elseif (class="Ens.BPL.If") {
			do ..ParseActivities(activity.True)
			do ..ParseActivities(activity.False)
		} elseif (class ="Ens.BPL.Switch"){
			do ..ParseActivities(activity.Cases)
		} else {
			set annotationText = $$$quote(activity.Annotation)
			do:activity.Annotation'="" %code.WriteLine(" quit:name=""" _ activity.Name _ """ ##class(isc.py.util.Evaluator).Evaluate(" _ annotationText _ ")")
		}
	}
}

}

