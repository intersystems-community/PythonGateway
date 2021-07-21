/// Generate custom query based on a Python DataFrame
Class isc.py.query.Generator [ Abstract ]
{

/// Main entry point.
/// variable - Python variable with DataFrame
/// classname - class to generate.
/// 
/// w $System.Status.GetErrorText(##class(isc.py.query.Generator).Generate("df", "test.df"))
ClassMethod Generate(variable As %String, classname As %Dictionary.CacheClassname) As %Status
{
	set sc = ##class(isc.py.Main).GetVariableDefined(variable, .defined)
	quit:$$$ISERR(sc) sc
	quit:'defined $$$ERROR($$$GeneralError, "Variable is not defined: " _ variable)
	
	set sc = ##class(%Dictionary.Classname).IsValid(classname)
	quit:$$$ISERR(sc) sc
	
	set sc = ##class(isc.py.Main).GetVariableJson(variable _ ".dtypes", .dtypes, $$$YES)
	quit:$$$ISERR(sc) sc
	
	#dim class As %Dictionary.ClassDefinition
	set class = ..GetInitialClass(classname)
	
	set columns = {}.%FromJSON(dtypes)
	set colNames = ""
	set iterator = columns.%GetIterator()
	
	set sequenceNumber = 1
	while iterator.%GetNext(.colName, .colDesc) {
		set colNames =  colNames _ $lb($case($zname(colName,6), 1: colName, 0: """" _ colName _ """"))
		do class.Properties.Insert(..GetColumn(colName, .colDesc, .sequenceNumber))
	}
	
	do class.Methods.Insert(..GetFetchCursor(colNames))
	do class.Parameters.Insert(..GetSQLNAME(classname))
	
	set sc = class.%Save()
	quit:$$$ISERR(sc) sc
	
	set sc = ..Compile(classname)		
	quit sc
}

/// Get class object. Populates docs and inheritance.
ClassMethod GetInitialClass(classname As %Dictionary.CacheClassname) As %Dictionary.ClassDefinition
{
	if ##class(%Dictionary.ClassDefinition).%ExistsId(classname) {
		do ##class(%Dictionary.ClassDefinition).%DeleteId(classname)
	}
	
	set class = ##class(%Dictionary.ClassDefinition).%New(classname, 26)
	set class.Super = "isc.py.query.Abstract, %SQL.CustomQuery"
	set class.GeneratedBy = $classname()
	set class.Description = "Custom Query for Python DataFrame"
	quit class
}

/// Generate property
ClassMethod GetColumn(colName As %String, colDesc As %DynamicObject, ByRef sequenceNumber) As %Dictionary.PropertyDefinition
{
	set sequenceNumber = sequenceNumber + 1
	set column = ##class(%Dictionary.PropertyDefinition).%New()
	set column.Name = colName
	set column.Type = "%String"
	set column.Description = colDesc.%ToJSON()
	set column.SequenceNumber = sequenceNumber
	quit column
}

/// Generate %FetchCursor method
ClassMethod GetFetchCursor(colNames As %List) As %Dictionary.MethodDefinition
{
	set method = ##class(%Dictionary.MethodDefinition).%New()
	set method.Name = "%FetchCursor"
	set method.ReturnType = "%Integer"
	do method.Implementation.WriteLine($c(9) _ "set $lb(i%" _ $lts(colNames, ", i%") _ ") = ..GetRow(.atEnd)")
	do method.Implementation.WriteLine($c(9) _ "quit 'atEnd")
	quit method
}

/// Generate SQLNAME parameter
ClassMethod GetSQLNAME(classname As %Dictionary.CacheClassname) As %Dictionary.ParameterDefinition
{
	set param = ##class(%Dictionary.ParameterDefinition).%New()
	set param.Name = "SQLNAME"
	set param.Type = "%String"
	set param.Default = $p(classname, ".", *)
	quit param
}

/// Compile generated class
ClassMethod Compile(classname) As %Status
{
	set displayFlags = "/checkuptodate=expandedonly /displaylog=0 /displayerror=0"	
	set sc = $system.OBJ.Compile(classname, "ckub" _ displayFlags, .errors)
	quit sc
}

}

