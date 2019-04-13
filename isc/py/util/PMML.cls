/// Utils to convert Python models to PMML and Import them
/// set sc = ##class(isc.py.util.PMML).Test()
Class isc.py.util.PMML
{

/// Save model as an InterSystems IRIS class
/// class - class to save model to. If exists would be overwrttten.
/// modelVar - python variable holding a model or a pipeline
/// featuresVar - python variable holding features 
/// target - python variable, holding name of target column.
/// verbose - display additional information
/// set sc = ##class(isc.py.util.PMML).SaveModel()
ClassMethod SaveModel(class As %String, modelVar As %String, featuresVar As %String = "features", targetVar As %String = "target", verbose As %Boolean = {$$$YES})
{
	#dim sc As %Status = $$$OK
	try {
		set filename = ##class(%File).TempFilename("pmml")
		
		// first check if this a pipeline or a straight model
		set sc = ##class(isc.py.Main).GetVariableType(modelVar, .type)
		quit:$$$ISERR(sc)
		if type '= "sklearn.pipeline.Pipeline" {
			// we'll need to wrap it for nyoka!
			set sc = ##class(isc.py.Main).ExecuteCode(modelVar _ "=Pipeline([('model'," _ modelVar _ ")])")
			quit:$$$ISERR(sc)
		} else {
			// assume the real model is at last step in the pipeline
			set sc = ##class(isc.py.Main).GetVariableType(modelVar _ ".steps[len(" _ modelVar _ ".steps)-1][1]", .type)
			quit:$$$ISERR(sc)
		}
		
		set sc = ##class(isc.py.Main).ImportModule("nyoka", , .nyoka)
		quit:$$$ISERR(sc)
		
		set pyPilename = ##class(isc.py.util.Converter).EscapeString(filename)
		
		if ($piece(type,".",1) = "sklearn") {
			set sc = ##class(isc.py.Main).ExecuteFunctionArgs(nyoka _ ".skl_to_pmml",,,, modelVar, featuresVar, targetVar, pyPilename)
		} elseif ($piece(type,".",1) = "xgboost") {
			set sc = ##class(isc.py.Main).ExecuteFunctionArgs(nyoka _ ".xgboost_to_pmml",,,, modelVar, featuresVar, targetVar, pyPilename)
		} else {
			// currenlty unsopported
			// Open an issue!
			set sc = $$$ERROR($$$GeneralError, "Unkown model type: " _ type)
		}
		quit:$$$ISERR(sc)
		
		// fix quirky version string and wordy <Extensions>
		set sc = ..FixPMML(filename)
		quit:$$$ISERR(sc)
		
		set sc = ##class(%DeepSee.PMML.Utils).CreateFromFile(filename, class, $$$YES, $$$NO, verbose)
		quit:$$$ISERR(sc)
		
		if verbose {
			set displayFlags = "/display=all"
		} else {
			set displayFlags = "/checkuptodate=expandedonly /displaylog=0 /displayerror=0"
		}
		
		set sc = $system.OBJ.Compile(class, displayFlags)
		quit:$$$ISERR(sc)
		
		do ##class(%File).Delete(filename)
		
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	quit sc
}

/// fix quirky version string and wordy <Extensions>
/// filename - model file
ClassMethod FixPMML(filename As %String) As %Status [ Internal ]
{
	#dim sc As %Status = $$$OK
	try {
		set file = ##class(%Stream.FileCharacter).%New()
		set sc = file.LinkToFile(filename)
		quit:$$$ISERR(sc)
		
		set stream = ##class(%Stream.TmpCharacter).%New()
		set sc = stream.CopyFrom(file)
		quit:$$$ISERR(sc)
		
		do file.Rewind()
		do stream.Rewind()
		
		// write <? xml line
		do file.WriteLine(stream.ReadLine())
		
		// fix version in main <PMML line
		set pmmlDef = stream.ReadLine()
		set versionPos = $find(pmmlDef, "version="""), 
			versionPosEnd = $find(pmmlDef, """", versionPos)-2,
			versionStr = $e(pmmlDef, versionPos, versionPosEnd)
		set fixedPMMLDef = $e(pmmlDef, 1, versionPos-1) _ $zstrip(versionStr, ">A") _ $e(pmmlDef, versionPosEnd+1, *)
		
		do file.WriteLine(fixedPMMLDef)
		
		// write the rest
		set inExtension=0
		while 'stream.AtEnd {
			set line = stream.ReadLine()
			if inExtension {
				if $e($zstrip(line, "<W"), 1, 12)="</Extension>" {
					set inExtension = 0
					continue
				}
			} else {
				if $e($zstrip(line, "<W"), 1, 10)="<Extension" {
					set inExtension = 1
					continue
				}
			}
			continue:inExtension

			set sc = file.WriteLine(line)
			quit:$$$ISERR(sc)
		}
		quit:$$$ISERR(sc)
		
		set sc = file.%Save()
		quit:$$$ISERR(sc)
		
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	quit sc
}

/// Create test model and save it as an InterSystems IRIS class 
/// set sc = ##class(isc.py.util.PMML).Test()
ClassMethod Test(class As %Dictionary.CacheClassname = "Test.SKLModel") As %Status
{
	set sc = $$$OK
	try {
		write !,"Init and import modules: "
		
		set sc = ##class(isc.py.Main).ImportModule("pandas", , .pandas)
		quit:$$$ISERR(sc)

		set sc = ##class(isc.py.Main).ImportModule("sklearn", , .sklearn)
		quit:$$$ISERR(sc)
		
		set sc = ##class(isc.py.Main).SimpleString("from sklearn import datasets")
		quit:$$$ISERR(sc)
		set sc = ##class(isc.py.Main).SimpleString("from sklearn.ensemble import RandomForestClassifier")
		quit:$$$ISERR(sc)		

		set sc = ##class(isc.py.Main).ImportModule("sklearn_pandas", , .sklearnPandas)
		quit:$$$ISERR(sc)
		
		write !,"Loading data"
		
		set sc = ##class(isc.py.Main).SimpleString("iris=datasets.load_iris()")
		quit:$$$ISERR(sc)

		set sc = ##class(isc.py.Main).SimpleString("irisd = " _ pandas _ ".DataFrame(iris.data,columns=iris.feature_names)")
		quit:$$$ISERR(sc)

		set sc = ##class(isc.py.Main).SimpleString("irisd['Species'] = iris.target")
		quit:$$$ISERR(sc)

		write !,"Build a simple model"
		set features = "features"
		set target = "target"
		set model = "pipeline"
		set sc = ##class(isc.py.Main).SimpleString(features _ " = irisd.columns.drop('Species')")
		quit:$$$ISERR(sc)
		set sc = ##class(isc.py.Main).SimpleString(target _ " = 'Species'")
		quit:$$$ISERR(sc)

		set code = model _ " = " _ sklearn _ ".pipeline.Pipeline([ "_
								"    ('mapping', " _ sklearnPandas _ ".DataFrameMapper(["_
								// commenting out this line, as it yields a transformation hitting PL146491
								//"    (['sepal length (cm)', 'sepal width (cm)'], StandardScaler()) ,"_
								"    (['petal length (cm)', 'petal width (cm)'], " _ sklearn _ ".preprocessing.Imputer()) "_
								"    ])), "_
								"    ('rfc', RandomForestClassifier(n_estimators = 100)) "_
							"])"
		
		set sc = ##class(isc.py.Main).SimpleString(code)
		quit:$$$ISERR(sc)
		
		write !,"Fit a simple model"

		set sc = ##class(isc.py.Main).SimpleString(model _ ".fit(irisd[" _ features _ "], irisd[" _ target _ "])")
		quit:$$$ISERR(sc)

		set sc = ..SaveModel(class, "pipeline", features, target)
		quit:$$$ISERR(sc)
		
	} catch (ex) {
		set sc = ex.AsStatus()
	}
	write:$$$ISERR(sc) $System.Status.GetErrorText(sc)
	quit sc
}

}

