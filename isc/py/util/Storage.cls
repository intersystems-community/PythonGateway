Class isc.py.util.Storage Extends %XML.Adaptor [ Abstract ]
{

/// Name of XData block that stores our data for population 
Parameter XDATA = "Data";

ClassMethod Export() As %Status
{
    quit:$classmethod($classname(), "%Extends", "%XML.Adaptor")=$$$NO $$$ERROR($$$GeneralError, "Class " _ $classname() _ " should extend %XML.Adaptor")
    
    if ##class(%Dictionary.XDataDefinition).IDKEYExists($classname(), ..#XDATA) {
        set xdata = ##class(%Dictionary.XDataDefinition).IDKEYOpen($classname(), ..#XDATA)
    } else {
        set xdata = ##class(%Dictionary.XDataDefinition).%New($classname() _  ":" _ ..#XDATA)
    }
    
    #dim stream As %Stream.TmpCharacter
    set stream = xdata.Data
    
    do stream.Clear()
    do stream.WriteLine("<xml>")
    
    set rs = ..ExtentFunc()
    while rs.%Next() {
        set obj = ..%OpenId(rs.ID)
        do obj.XMLExportToStream(.stream)
        do stream.WriteLine()
    }
    do stream.WriteLine("</xml>")
    quit xdata.%Save()
}

ClassMethod Import() As %Status
{
	#dim sc As %Status = $$$OK
	set xdata = ##class(%Dictionary.XDataDefinition).IDKEYOpen($classname(), "Data")
	
	#dim stream As %Stream.TmpCharacter 
	set stream = xdata.Data
	
	set reader = ##class(%XML.Reader).%New()
	set sc=reader.OpenStream(stream)
	quit:$$$ISERR(sc) sc
	do reader.Correlate(..GetXMLName(), $classname())
	
	do ..%KillExtent()
	while reader.Next(.obj, .sc) {
		set sc = obj.%Save()
		quit:$$$ISERR(sc)
	}
	
	quit sc
}

/// Get class XMLName
/// w ##class(isc.py.util.Storage).GetXMLName()
ClassMethod GetXMLName(class As %Dictionary.CacheClassname = {$classname()}) As %String
{
    set xmlname = ..#XMLNAME
    set:xmlname="" xmlname = $$$ClassShortName(class)
    quit xmlname
}

}

