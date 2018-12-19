/// Utilities for Python PB
Class isc.py.ens.ProcessUtils
{

/// Get value of activity annatation by name
ClassMethod GetAnnotation(name) As %String [ CodeMode = objectgenerator ]
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
				
			for i=1:1:activities.Count() {
				#dim activity As Ens.BPL.Activity
				set activity = activities.GetAt(i)
				set annotationText = $$$quote(activity.Annotation)
				do:activity.Annotation'="" %code.WriteLine(" quit:name=""" _ activity.Name _ """ " _ annotationText)
			}
			do %code.WriteLine(" quit """"")
        }
    } catch ex {
	    set sc = ex.AsStatus()
    }
    quit sc
}

}

