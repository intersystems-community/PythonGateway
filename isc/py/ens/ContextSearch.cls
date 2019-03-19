/// Context search for ensemble/interopeability production hosts
Class isc.py.ens.ContextSearch Extends %ZEN.Portal.ContextSearch
{

/// Get list of subclasses
ClassMethod SubclassOf(Output caption As %String, Output topResults, Output results, ByRef parms As %String, searchKey As %String = "") As %Status
{
	#dim sc AS %Status = $$$OK
	kill results, topResults
	set caption = "Модели ПУ"
	
	try {

		/// Really %sqlcq.<NAMESPACE>.cls<NUMBER>
		#dim rs As %SQL.ISelectResult
		set rs = ##class(%Dictionary.ClassDefinitionQuery).SubclassOfFunc(parms("class"))
		while rs.%Next() {
			set results($i(results)) = rs.Name
		}		
	} catch ex {
		set sс = ex.AsStatus()
	}

	quit sc
}

}

