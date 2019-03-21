/// Execute BP in a current job
Class isc.py.util.BPEmulator
{

/// Execute intra process
/// do ##class(isc.py.util.BPEmulator).ExecuteIntra()
ClassMethod ExecuteIntra()
{
	set class = "CONVERGENCE.WEB.INTRA"
	set activities = $lb("Import Python Libraries", 
						 $lb("Query In Time Series", "df"), 
						 "Histroric Time Series", 
						 "Decompose Time Series",
						 "Explore Modeling Space",
						 "Explore Selected Model",
						 "Create Forecast")
	do ..RunActivities(class, activities)
}

/// Execute test process
/// do ##class(isc.py.util.BPEmulator).ExecuteTest()
ClassMethod ExecuteTest()
{
	set class = "isc.py.test.Process"
	set activities = $lb("Import pandas", 
						 $lb("RAW", "Data"), 
						 "Correlation Matrix: Tabular", 
						 "Correlation Matrix: Graph")
	do ..RunActivities(class, activities)
}

/// Execute campaign process
/// do ##class(isc.py.util.BPEmulator).ExecuteCampaign()
ClassMethod ExecuteCampaign()
{
	set class = "CONVERGENCE.WEB.CAMPAIGN"
	set activities = $lb("Import Python Libraries", 
						 $lb("Query In Testing Set", "Data_test"), 
						 $lb("Query In Training Set", "Data_train"), 
						 "Form Testing Set", 
						 "Form Training Set", 
						 "Split Training Set", 
						 "Initialize LR", 
						 "Fit/Apply GB + LR")
	do ..RunActivities(class, activities)
}

/// Execute activities from class
ClassMethod RunActivities(class As %Dictionary.CacheClassname, activities As %List)
{
	for i=1:1:$ll(activities) {
		set activity = $lg(activities, i)
		
		write "Executing: "
		set start = $zh
		if $listvalid(activity) {
			write $lg(activity)," (query), into variable: ", $lg(activity, 2)
			set sc = ..ExecuteQuery(class, $lg(activity), $lg(activity, 2), "RAW")
		} else {
			write activity
			set sc = ..ExecuteCode(class, activity)
		}
		set end = $zh
		
		write " result: ", $case($$$ISOK(sc), $$$YES:"OK", $$$NO: $System.Status.GetErrorText(sc)),", Time: ",end-start," sec.",!
		break:$$$ISERR(sc)
	}
}

/// Execute code activity
/// w ##class(isc.py.util.BPEmulator).ExecuteCode()
ClassMethod ExecuteCode(class, name) As %Status
{
	set code = $classmethod(class, "GetAnnotation", name)
	set sc = ##class(isc.py.Main).SimpleString(code)
	quit sc
}

/// Execute Query activity
/// w ##class(isc.py.util.BPEmulator).ExecuteQuery()
ClassMethod ExecuteQuery(class, name, variable, mode As %String = "RAW") As %Status
{
	set query = $classmethod(class, "GetAnnotation", name)
	if mode = "RAW" {
		set sc = ##class(isc.py.Main).ExecuteQuery(query, variable, "dataframe")
	} elseif mode = "ODBC" {
		set sc = ##class(isc.py.Main).ImportModule("pyodbc", , .pyodbc)
		set sc = ##class(isc.py.Main).ImportModule("pandas", , .pandas)
		set sc = ##class(isc.py.Main).SimpleString("cnxn=" _ pyodbc _ ".connect(('DSN=ENSEMBLE(PYTHON);UID=dev;PWD=123'),autocommit=True)")
		set sc = ##class(isc.py.Main).SimpleString(variable _ "=" _ pandas _".read_sql('"_ query _ "',cnxn)")
		//set sc = ##class(isc.py.Main).SimpleString("cnxn.close()")
	} elseif mode = "JDBC" {		
		set sc = ##class(isc.py.Main).ImportModule("jaydebeapi", , .jaydebeapi)
		set sc = ##class(isc.py.Main).ImportModule("pandas", , .pandas)
		set sc = ##class(isc.py.Main).SimpleString("cnxn=" _ jaydebeapi _ ".connect(""com.intersystems.jdbc.IRISDriver"",""jdbc:IRIS://localhost:51773/Python"",  [""dev"", ""123""], ""/InterSystems/IRIS/dev/java/lib/JDK18/intersystems-jdbc-3.0.0.jar"")")
		set sc = ##class(isc.py.Main).SimpleString(variable _ "=" _ pandas _".read_sql('"_ query _ "',cnxn)")
		set sc = ##class(isc.py.Main).SimpleString("cnxn.close()")		
	} else {
		set sc = $$$ERROR($$$GeneralError, "Unknown query mode: " _ mode)
	}
	quit sc
}

/// w ##class(isc.py.util.BPEmulator).DescribeDataframe()
ClassMethod DescribeDataframe(variable) As %Status
{
	set sc = ##class(isc.py.Main).SimpleString("zzzinfo=" _ variable _ ".dtypes", "zzzinfo", , .zzzinfo)
	quit:$$$ISERR(sc) sc
	write $replace(zzzinfo, $c(10), $$$NL)
	set sc = ##class(isc.py.Main).SimpleString("del zzzinfo")
	quit sc
}

}

