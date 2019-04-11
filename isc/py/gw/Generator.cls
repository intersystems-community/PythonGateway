/// Generate IRIS classes from Pyhton types 
Class isc.py.gw.Generator Extends %RegisteredObject
{

Parameter MaxMethods = 1900;

Parameter MaxProperties = 950;

/// Display logging info. Increasing the number shows more messages.
/// -1 display nothing
/// 0 - display modules info
/// 1 - display types info
/// 2 - display methods/properties info
Property LogLevel As %Integer [ InitialExpression = 1 ];

Property Initialized As %Boolean [ InitialExpression = {$$$NO} ];

/// Already done python types
Property GeneratedTypeList As %List;

/// Work to do - python types
Property TypeList As %List;

/// Created IRIS classes
Property ClassList As %List;

/// Base package for generated classes
Property Package As %String [ InitialExpression = "py" ];

/// Inspect alias
Property Inspect As %String [ InitialExpression = "inspect" ];

/// Module alias we're currently importing
Property Module As %String;

/// Base class for all python classes
Property BaseClass As %Dictionary.CacheClassname [ InitialExpression = "isc.py.gw.DynamicObject" ];

/// Class that fixes Method/Classmethod and Signatures
Property FixClass As %Dictionary.CacheClassname [ InitialExpression = "isc.py.util.Generator" ];

/// List of modules loaded in memory
Property ImportedModulesList As %List;

/// List of currently generated proprties in lowercase
Property CurrentPropertiesList As %List;

/// List of currently generated methods in lowercase
Property CurrentMethodsList As %List;

/// Warnings, usually about failures to generate something
Property Warnings As list Of %String;

/// Classes satisfying this mask would be imported
Property ClassesWhiteMask As %String [ InitialExpression = "*" ];

/// Classes satisfying this mask would not be imported
Property ClassesBlackMask As %String [ InitialExpression = "*_*" ];

/// Methods satisfying this mask would be imported
Property MethodsWhiteMask As %String [ InitialExpression = "*,__init__" ];

/// Methods satisfying this mask would not be imported
Property MethodsBlackMask As %String [ InitialExpression = "_*,*_" ];

/// Properties satisfying this mask would be imported
Property PropertiesWhiteMask As %String [ InitialExpression = "*" ];

/// Properties satisfying this mask would not be imported
Property PropertiesBlackMask As %String [ InitialExpression = "_*,*_" ];

/// Generate a  list of python modules
/// set sc = ##class(isc.py.gw.Generator).Import()
ClassMethod Import(modules As %List = {$lb("builtins", "random")}) As %Status
{
	quit:modules="" $$$ERROR($$$GeneralError, "Provide a list of modules")
	set:'$listvalid(modules) modules = $lb(modules)
	
	set obj = ..%New()
	set sc = $system.OBJ.DeletePackage(obj.Package)
	quit:$$$ISERR(sc) sc
	
	for i=1:1:$ll(modules) {
		set sc = obj.GenerateModule($lg(modules, i))
		write $System.Status.GetErrorText(sc)
		quit:$$$ISERR(sc)
	}
	set:$$$ISOK(sc) sc = obj.Compile()
	quit sc
}

/// Compile all generated classes
Method Compile()
{
	#include %occErrors
	set irisClasses = ""
	set ptr=0
	
	if ..LogLevel>0 {
		set displayFlags = "/display=all"
	} else {
		set displayFlags = "/checkuptodate=expandedonly /displaylog=0 /displayerror=0"
	}
	
	set sc = $system.OBJ.Compile($lts(..ClassList), "cuks /checkuptodate=expandedonly " _ displayFlags, .errors)
		
	write "Compile error fixes: ",!
	for i=1:1:errors {
		set errorCode = errors(i, "code")
		if errorCode=$$$KeywordSignatureError {
			set class = $p(errors(i,"param",1), ":", 1)
			set type = $$$defMemberKeyGet(class,$$$cCLASSparameter,"Type",$$$cPARAMdefault)
			
			set method = $p(errors(i,"param",1), ":", 3)
			set isClassMethod = errors(i,"param", 3)
			
			set methods(type, isClassMethod) = $g(methods(type, isClassMethod)) _ $lb(method)
		}
	}
	
	set type="" 
	for {
		set type = $o(methods(type))
		quit:type=""
		
		set isClassMethod=""
		for {
			set isClassMethod = $o(methods(type, isClassMethod),1,methodList)
			quit:isClassMethod=""
			
			if $ll(methodList)=1 {
				write "quit:((type=""" _ type _ """) && (method="""_$lg(methodList)_""")) " _ $case(isClassMethod, $$$YES:"$$$YES", :"$$$NO"),!
			} else {
				write "quit:((type=""" _ type _ """) && ($lf($lb("""_$lts(methodList, """,""")_"""),method))) " _ $case(isClassMethod, $$$YES:"$$$YES", :"$$$NO"),!
			}	
		}
	}	
	
	write "Compile error fixes end. ",!
	
	do ..DisplayWarnings()
	
	quit sc
}

Method DisplayWarnings()
{
	write "Warnings: ",..Warnings.Count(),!
	for i = 1:1:..Warnings.Count() {
		write ..Warnings.GetAt(i),!
	}
	write "End warnings.",!
}

/// Generate module
Method GenerateModule(module) As %Status
{
	if '..Initialized {
		set sc = ##class(isc.py.init.Generator).Initialize(,(..LogLevel>0))
		quit:$$$ISERR(sc) sc
		set ..Initialized = $$$YES
	}
	
	set sc = ##class(isc.py.Main).ImportModule(module, .imported, .alias)
	quit:$$$ISERR(sc) sc
	
	set ..Module = alias
	do ..AppendToTypeList($lb(alias))
	
	do ..AppendImportedModule(alias)
		
	do ..Log(0, "Generating module: %1 alias %2 into package: %3", module, alias, ..Package)
	
	set sc = ..GetModuleTypes(alias, .classes)
	do ..AppendToTypeList(classes)

	while $ll(..TypeList)>0 {
		set type = $lg(..TypeList, *)
		set $li(i%TypeList, *, *) = ""
		
		set sc = ..CheckImportedModule(type)
		quit:$$$ISERR(sc)
		
		set sc = ##class(isc.py.Main).GetVariableDefined(type, .defined)
		quit:$$$ISERR(sc)
		
		if defined {
			set sc = ..GenerateClass(type)
		} else {
			set warning = "Failed to find class '" _ type _ "' for generation"
			do ..Log(0, warning)
			do ..Warnings.Insert(warning)
			
			set sc = ..GenerateMissingClass(type)
			
		}
		quit:$$$ISERR(sc)
		set ..GeneratedTypeList = ..GeneratedTypeList _ $lb(type)
		set ..ClassList = ..ClassList _ $lb(..TypeToClass(type))
	}
	quit:$$$ISERR(sc) sc
	
	quit sc
}

/// Generate IRIS type from Python type
Method GenerateClass(type As %String) As %Status
{
	#dim sc As %Status = $$$OK
	do ..Log(1, "Generating type: %1", type)

	set sc = ..GetInitialClass(type, .classObj)
	quit:$$$ISERR(sc) sc
	
	do ..GenerateTypeParameter(type, classObj)
	
	set sc = ..GetTypeMembers(type, "callable", .methods)
	quit:$$$ISERR(sc) sc
	set methods = ##class(isc.py.util.Matcher).FilterList(methods, ..MethodsWhiteMask, ..MethodsBlackMask)
	
	set methodsCount = $ll(methods)
	if methodsCount>..#MaxMethods {
		set warning = $$$FormatText("Type '%1' contains %2 methods. Generating only first %3 methods", type, methodsCount, ..#MaxMethods) 
		do ..Log(0, warning)
		do ..Warnings.Insert(warning)
		set methods = $list(methods, 1, ..#MaxMethods)
		set methodsCount = ..#MaxMethods
	}
	
	set ..CurrentMethodsList = ""
	set ptr=0
	while $listnext(methods, ptr, method) {
		set sc = ..GenerateMethod(type, classObj, method) 
		quit:$$$ISERR(sc)
	}
	quit:$$$ISERR(sc) sc
	
	set sc = ..GetTypeMembers(type, "zzzuncallable", .properties)
	quit:$$$ISERR(sc) sc
	set properties = ##class(isc.py.util.Matcher).FilterList(properties, ..PropertiesWhiteMask, ..PropertiesBlackMask)
	
	set propertiesCount = $ll(properties)
	
	if (propertiesCount>..#MaxProperties) {
		set warning = $$$FormatText("Type '%1' contains %2 properties. Generating only first %3 properties", type, propertiesCount, ..#MaxProperties) 
		do ..Log(0, warning)
		do ..Warnings.Insert(warning)
		set properties = $list(properties, 1, ..#MaxProperties)
		set propertiesCount = ..#MaxProperties
	}
	
	set ..CurrentPropertiesList = ""
	set ptr=0
	while $listnext(properties, ptr, property) {
		set sc = ..GenerateProperty(classObj, property) 
		quit:$$$ISERR(sc)
	}
	quit:$$$ISERR(sc) sc
	
	set sc = classObj.%Save()
	
	quit sc
}

/// Generate empty class so compilation succeeds.
Method GenerateMissingClass(type As %String) As %Status
{
	#dim sc As %Status = $$$OK
	set class = ..TypeToClass(type)
	if ##class(%Dictionary.ClassDefinition).%ExistsId(class) {
		set warning = $$$FormatText("Duplicate generation hit on missing type %1, class %2,", type, class)
		do ..Warnings.Insert(warning)
		do ..Log(3, warning)
	} else {
		set classObj = ##class(%Dictionary.ClassDefinition).%New(class)	
		do classObj.ProcedureBlockReset()
		set classObj.Abstract = $$$YES
			
		set classObj.Description = "Pyhton type: " _ type _ $$$NL _ "This type can't be found by name."
		set classObj.Super = ..BaseClass
		
		do ..GenerateTypeParameter(type, classObj)
		set sc = classObj.%Save()
	}
	
	quit sc
}

/// Get class object. Populates docs and inheritance.
Method GetInitialClass(type As %String, Output classObj As %Dictionary.ClassDefinition) As %Status
{
	#dim sc As %Status = $$$OK
	set class = ..TypeToClass(type)
	if ##class(%Dictionary.ClassDefinition).%ExistsId(class) {
		set warning = $$$FormatText("Duplicate generation hit on type %1, class %2,", type, class)
		do ..Warnings.Insert(warning)
		do ..Log(3, warning)
	} else {
		set classObj = ##class(%Dictionary.ClassDefinition).%New(class)	
		do classObj.ProcedureBlockReset()
		
		set sc = ..IsAbstract(type, .isAbstract)
		quit:$$$ISERR(sc) sc
		set:isAbstract classObj.Abstract = isAbstract
		
		set sc = ##class(isc.py.Main).SimpleString("zzzdocs=" _ ..Inspect _ ".getdoc(" _ type _ ")", "zzzdocs", , .docs)
		quit:$$$ISERR(sc) sc
		set sc = ##class(isc.py.Main).SimpleString("del zzzdocs")
		set:docs="None" docs = ""
		
		set classObj.Description = "Pyhton type: " _ type _ $$$NL _ $replace(docs, $c(10), $$$NL) _ $$$NL _ ..GenerateCall(classObj.Name, "%OnNew", $$$NO) 
		
		set sc = ##class(isc.py.Main).SimpleString("zzzextends=json.dumps([item.__module__ + '.' + item.__name__ for item in " _ ..Inspect _ ".getmro(" _ type _ ")])", "zzzextends", , .zzzextends)
		// TODO - modules
		if $$$ISERR(sc) {
			set sc = $$$OK
			set classObj.Super = ..BaseClass
		} else {
			set obj = [].%FromJSON(zzzextends)
			
			set extends = ""
			set irisExtends = ""
			set iterator = obj.%GetIterator()
			while iterator.%GetNext(.key, .value) {			
				set value = $replace(value, "<unknown>", ..Module)
				continue:value=type
				continue:##class(isc.py.util.Matcher).FilterList($lb(value), ..ClassesWhiteMask, ..ClassesBlackMask)=""
				set extends = extends _ $lb(value)
				set irisExtends = irisExtends _ $lb(..TypeToClass(value))
			}
			
			for i=1:1:$ll(irisExtends) {
				set irisExtendsClass = $lg(irisExtends, i)
				if classObj.Name'=irisExtendsClass {
					set classObj.Super = irisExtendsClass
					quit
				}
			}
			set:classObj.Super="" classObj.Super = ..BaseClass
			do ..AppendToTypeList(extends)
		}
	}
		
	quit sc
}

/// Generate property code.
Method GenerateProperty(classObj As %Dictionary.ClassDefinition, property As %String) As %Status
{
	#dim sc As %Status = $$$OK
	do ..Log(2, "Property: %1", property)
	
	set irisProperty = ..FixPropertyName(property)
	
	#dim propIndex As %Integer = classObj.Properties.FindObjectId(classObj.Name _ "||" _ irisProperty)
	if propIndex = "" {
		set propObj = ##class(%Dictionary.PropertyDefinition).%New()
		set propObj.Name = irisProperty
		set propObj.parent = classObj
		set propObj.Type = "isc.py.gw.PyString"
		set propObj.Description = "Python property: " _ property
		do:irisProperty'=property propObj.Parameters.SetAt(property, "PyName")
	}
	
	quit sc
}

/// Add number to property name if property name already exists.
/// This is a fix for the fact that Python attributes are case sensitive and ObjectScript properties are not. 
Method FixPropertyName(property) As %String
{
	set lowerProperty = $zcvt(property, "l")
	for i="",1:1:$$$MaxCacheInt {
		quit:$lf(..CurrentPropertiesList, lowerProperty _ i)=0
	}
	set ..CurrentPropertiesList = ..CurrentPropertiesList _ $lb(lowerProperty _ i)
	quit property _ i
}

/// Add Type parameter to IRIS Class
ClassMethod GenerateTypeParameter(type As %String, Output classObj As %Dictionary.ClassDefinition)
{
	set name = "Type"
	#dim paramIndex As %Integer = classObj.Parameters.FindObjectId(classObj.Name _ "||" _ name)
	if paramIndex = "" {
		set paramObj = ##class(%Dictionary.ParameterDefinition).%New()
		set paramObj.Name = name
		set paramObj.parent = classObj
		set paramObj.Type = "%String"
		set paramObj.Description = "Python type"
		set paramObj.Default = type
	}
}

/// TODO - skip udserscore classes?
/// Translate python FQCN to IRIS class.
Method TypeToClass(type As %String) As %String
{
	if ((type'=..Module) && ($l(type,".")=1)) {
		set type = "builtins." _ type	
	}
	quit $zstrip($tr(..Package _ "." _ type, "_", "."),"=>P")
}

/// Translate method argument names from Python to IRIS.
ClassMethod VarNameToIRIS(string) As %String
{
	set arg = $tr(string, "_")
	set:arg="" arg = "arg" _ $l(string)
	quit arg
}

/// Generate method code.
Method GenerateMethod(type As %String, classObj As %Dictionary.ClassDefinition, method As %String) As %Status
{
	#dim sc As %Status = $$$OK
	do ..Log(2, "Method: %1", method)
	set sc = ##class(isc.py.Main).GetFunctionInfo(type _ "." _ method, .defined, .methodType, .docs, .signature, .arguments)
	quit:$$$ISERR(sc) sc
	
	do $classmethod(..FixClass, "GetArguments", type, method, .arguments)
	
	set irisMethod = $case(method, "__init__":"%OnNew", : ..FixMethodName(method))
	
	#dim methodIndex As %Integer = classObj.Methods.FindObjectId(classObj.Name _ "||" _ irisMethod)
	if methodIndex = "" {
		set methodObj = ##class(%Dictionary.MethodDefinition).%New()
		
		set methodObj.Name = irisMethod
		set methodObj.parent = classObj
		set methodObj.Description = "Signature: " _ signature _ $$$NL _ "Type: " _ methodType _ $$$NL _ $replace(docs, $c(10), $$$NL) _ $$$NL
		
		set sc = ..IsAbstract(type _ "." _ method, .isAbstract)
		quit:$$$ISERR(sc) sc
		set methodObj.Abstract = isAbstract
		
		// Is it class or object method? - Start
		set methodObj.ClassMethod = $$$YES
		set:methodType="method" methodObj.ClassMethod = $$$NO
		set:methodType="method_descriptor" methodObj.ClassMethod = $$$NO
		// Module methods can always be called
		set:type=..Module methodObj.ClassMethod = $$$YES
		
		set isClassMethod = $classmethod(..FixClass, "IsClassMethod", type, method)
		set:isClassMethod'="" methodObj.ClassMethod = isClassMethod
		// Is it class or object method? - End
		// Not really the end
		
		// start - calculating signatures
		if arguments="" {
			set formalSpec = "args..."
			set callArgs = "..%CallArgsToString(args...)"
		} else {
			set arguments = $replace(arguments, "NaN", "null")
			#dim funcArgObj As %DynamicArray = [].%FromJSON(arguments)
			// If it has self arg, it's probably an instance method
			
			if (($isObject(funcArgObj.%Get(0))) && (type'=..Module)) { 
				if (funcArgObj.%Get(0).%Get(0)="self") {
					set methodObj.ClassMethod = $$$NO
				} else {
					set methodObj.ClassMethod = $$$YES
				}
			} else {
				set methodObj.ClassMethod = $$$YES
			}
			set:isClassMethod'="" methodObj.ClassMethod = isClassMethod

			do ..GenereateMethodSignature(funcArgObj, .formalSpec, .callArgs)
		}	
		// end - calculating signatures
		
		do ..GenerateMethodBody(methodObj, type, method, formalSpec, callArgs)
		set methodObj.Description = methodObj.Description _  ..GenerateCall(classObj.Name, irisMethod, methodObj.ClassMethod) 
	}
	quit sc
}

/// Add number to method name if property name already exists.
/// This is a fix for the fact that Python attributes are case sensitive and ObjectScript methods are not. 
Method FixMethodName(method) As %String
{
	set lowerMethod = $zcvt(method, "l")
	for i="",1:1:$$$MaxCacheInt {
		quit:'$lf(..CurrentMethodsList, lowerMethod _ i)
	}
	set ..CurrentMethodsList = ..CurrentMethodsList _ $lb(lowerMethod _ i)
	quit method _ i
}

/// Generate ObjectScript code to call method of class.
ClassMethod GenerateCall(class As %String, method As %String, classMethod As %Boolean) As %String
{
	if method = "%OnNew" {
		set command = "set obj = "
	} else {
		set command ="write "
	}
	
	if (classMethod || (method="%OnNew")){
		set objCall = "##class(" _ class _ ")"
	} else {
		set objCall = "obj"
	}
	 
	if $zname(method, 6) = 0 {
		set methodCall = """" _ method _ """"
	} elseif method="%OnNew" {
		set methodCall = "%New"
	} else {
		set methodCall = method
	}
	
	set call = command _ objCall _ "." _ methodCall _ "()"
	quit call
}

/// From pyton signature funcArgObj determine:
/// - formalSpec - method signature
/// - callArgs - arguments to call python code
ClassMethod GenereateMethodSignature(funcArgObj As %DynamicArray, Output formalSpec, Output callArgs)
{
	// Method signature
	set formalSpec = ""
	
	// python call signature 
	set callArgs = ""
	
	// Are we currently on first arg
	#dim firstArg As %Boolean = $$$YES
	
	#dim args As %DynamicArray = funcArgObj.%Get(0)
	#dim varargs As %String = funcArgObj.%Get(1)
	#dim varkw As %String = funcArgObj.%Get(2)
	#dim defaults As %DynamicArray = funcArgObj.%Get(3)
	#dim kwonlyargs As %DynamicArray = funcArgObj.%Get(4)
	#dim kwonlydefaults As %DynamicArray = funcArgObj.%Get(5)
	
	// Remove self argument if it's a method or a constructor function
	if (($isObject(args) && (args.%Get(0)="self"))) {
		do args.%Remove(0)
	}

	#dim posCount As %Integer = $case($isObject(args), $$$YES: args.%Size(), :0)
	#dim kwCount As %Integer = $case($isObject(kwonlyargs), $$$YES: kwonlyargs.%Size(), :0)
	#dim hasArgs As %Boolean = (varargs'="")
	#dim hasKWArgs As %Boolean = (varkw'="")
 
	set iterator = args.%GetIterator()
	while iterator.%GetNext(.key, .value) {
		set formalSpec = formalSpec _ $case(firstArg, $$$YES:"", :", ") _ ..VarNameToIRIS(value)
		set callArgs = callArgs _ $case(firstArg, $$$YES:"", :"_"",""_") _ "..%EscapeArg(." _ ..VarNameToIRIS(value) _ ")"
		set firstArg = $$$NO
			
		//set default = $case($isObject($g(defaults)), $$$YES:defaults.%Get(key), :"")
		//set:default'="" formalSpec = formalSpec _ "=" _ default
	}
	
	if hasArgs {
		set formalSpec = formalSpec _ $case(firstArg, $$$YES:"", :", ") _ ..VarNameToIRIS(varargs)
		set callArgs = callArgs _ $case(firstArg, $$$YES:"", :"_"",""_") _ "..%ArgsToString(." _ ..VarNameToIRIS(varargs) _ ")"
		set firstArg = $$$NO
	}
	
	set iterator = kwonlyargs.%GetIterator()
	while iterator.%GetNext(.key, .value) {			
		set formalSpec = formalSpec _ $case(firstArg, $$$YES:"", :", ") _ ..VarNameToIRIS(value)		
		set callArgs = callArgs _ $case(firstArg, $$$YES:"", :"_"",""_") _ "..%EscapeKWArg(""" _ value _ """, ." _ ..VarNameToIRIS(value) _ ")"
		set firstArg = $$$NO

		//set default = $case($isObject($g(kwonlydefaults)), $$$YES:kwonlydefaults.%Get(key), :"")
		//set:default'="" formalSpec = formalSpec _ "=" _ default
	}
	
	if hasKWArgs {
		set formalSpec = formalSpec _ $case(firstArg, $$$YES:"", :", ") _ ..VarNameToIRIS(varkw)
		set callArgs = callArgs _ $case(firstArg, $$$YES:"", :"_"",""_") _ "..%KWArgsToString(." _ ..VarNameToIRIS(varkw) _ ")"
		set firstArg = $$$NO
	}
	
	// Remove trailing commas
	set:callArgs'="" callArgs = "$zstrip(" _ callArgs _ ","">"","","")"
}

ClassMethod GenerateMethodBody(methodObj As %Dictionary.MethodDefinition, class, method, formalSpec, callArgs)
{
	if methodObj.Name = "%OnNew" {
		do ..FixOnNewArgs(.formalSpec, .callArgs)
		do ..GenerateOnNewMethodBody(methodObj, formalSpec, callArgs)
	} else {
		do ..GenerateCommonMethodBody(methodObj, class, method, formalSpec, callArgs)
	}
	
	do:methodObj.Abstract methodObj.Implementation.Clear()
}

/// Fix formalSpec and callArgs for %OnNew method if they contain "init" and/or "variable" arguments already 
ClassMethod FixOnNewArgs(ByRef formalSpec, ByRef callArgs)
{
	for variable = "init","variable" {
		if $find(formalSpec, variable)>0 {
			set formalSpec = $replace(formalSpec, variable, variable _ "Arg")
			set callArgs = $replace(callArgs, variable, variable _"Arg")
		}
	}
}

/// Generate %OnNew method
ClassMethod GenerateOnNewMethodBody(methodObj As %Dictionary.MethodDefinition, formalSpec As %String, callArgs As %String)
{
	set methodObj.ClassMethod = $$$NO
	set methodObj.ReturnType = "%Status"
	set methodObj.FormalSpec = "init:%String=$$$YES,variable:%String=..%GetNewVar()" _ $case(formalSpec'="", $$$YES:", ", :"") _ formalSpec 
	
	do methodObj.Implementation.WriteLine($c(9) _ "set ..%Variable = variable")
	
	do methodObj.Implementation.WriteLine($c(9) _ "if init {")
	do methodObj.Implementation.WriteLine($c(9,9) _ "$$$TOE(sc, ##class(isc.py.Main).SimpleString(variable _ "" = "" _ ..%Type _ ""("_ $case(callArgs, "":"", :"""_" _ callArgs _ "_""") _ ")""))")
	do methodObj.Implementation.WriteLine($c(9) _ "} else {")	
	do methodObj.Implementation.WriteLine($c(9,9) _ "$$$TOE(sc, ##class(isc.py.Main).GetVariableDefined(variable, .defined))")
	do methodObj.Implementation.WriteLine($c(9,9) _ "throw:'defined ##class(%Exception.General).%New(""<VARIABLE>"", variable)")
		
	do methodObj.Implementation.WriteLine($c(9,9) _ "$$$TOE(sc, ##class(isc.py.Main).GetVariableType(variable, .type))")
	do methodObj.Implementation.WriteLine($c(9,9) _ "throw:..%Type'=$g(type) ##class(%Exception.General).%New(""<VARIABLE>"", type _"" is not "" _ ..%Type)")
	do methodObj.Implementation.WriteLine($c(9) _ "}")
	
	do methodObj.Implementation.WriteLine($c(9) _ "quit sc")
}

/// Generate all other methods.
ClassMethod GenerateCommonMethodBody(methodObj As %Dictionary.MethodDefinition, class, method, formalSpec, callArgs)
{
	// start - calculating caller obj on Python side
	if methodObj.ClassMethod {
		set caller =  class _ "." _ method
	} else {
		set caller = """ _ ..%Variable _ ""."_ method
	}
	// end - calculating caller obj on Python side
	
	do methodObj.Implementation.WriteLine($c(9) _ "set variable = ..%GetNewVar()")
	
	do methodObj.Implementation.WriteLine($c(9) _ "$$$TOE(sc, ##class(isc.py.Main).SimpleString(variable _ "" = " _ caller _ "("_ $case(callArgs, "":"", :"""_" _ callArgs _ "_""") _ ")"", variable, , .result))")
	
	do methodObj.Implementation.WriteLine($c(9) _ "$$$TOE(sc, ##class(isc.py.Main).GetVariableType(variable, .type))")
	
	do methodObj.Implementation.WriteLine($c(9) _ "if ..%IsPrimitive(type) = $$$NO {")
	do methodObj.Implementation.WriteLine($c(9,9) _ "set result = $classmethod(..%TypeToClass(type), ""%New"", $$$NO, variable)")
	do methodObj.Implementation.WriteLine($c(9) _ "}")
	do methodObj.Implementation.WriteLine($c(9) _ "quit result")
	set methodObj.FormalSpec = formalSpec
}

/// Check that module definig type is imported
Method CheckImportedModule(type) As %Status
{
	#dim sc As %Status = $$$OK
	quit:$l(type, ".")=1 sc
	set module = $p(type, ".", 1)
	if $lf(..ImportedModulesList, module)=0 {
		set sc = ##class(isc.py.Main).ImportModule(module, .imported, .alias)
		quit:$$$ISERR(sc) sc

		// fix for cases where module is already imported.
		// we need canonical name
		set:alias'=module sc = ##class(isc.py.Main).SimpleString(module _ "=" _ alias)
		quit:$$$ISERR(sc) sc
		
		do ..AppendImportedModule(module)
	}
	
	quit sc
}

/// Add imported module to ImportedModulesList property
Method AppendImportedModule(module As %String)
{
	if $lf(..ImportedModulesList, module)=0 {
			set ..ImportedModulesList = ..ImportedModulesList _ $lb(module)
	}
}

/// Append a %List of python types to TypeList.
/// If GeneratedTypeList or TypeList alredy clontain python type it would be skipped.
Method AppendToTypeList(types As %List)
{
	set types = ##class(isc.py.util.Matcher).FilterList(types, ..ClassesWhiteMask, ..ClassesBlackMask)
	set ptr=0
	while $listnext(types, ptr, type) {
		if ((type'=..Module) && ($l(type,".")=1)) {
			set type = "builtins." _ type	
		}
		
		if (($lf(..GeneratedTypeList, type)=0) && ($lf(..TypeList, type)=0)) {
			set ..TypeList = ..TypeList _ $lb(type)
		}
	}
}

/// Check if callable object is abstract
ClassMethod IsAbstract(object As %String, Output isAbstract As %Boolean) As %Status
{
	kill isAbstract
	#dim sc As %Status = $$$OK
	set sc = ##class(isc.py.Main).SimpleString("zzzisabstract = inspect.isabstract(" _ object _ ")", "zzzisabstract", ,.isAbstract)
	quit:$$$ISERR(sc) sc
	
	set isAbstract = ##class(isc.py.util.Converter).PythonToBoolean(isAbstract)	
	set sc = ##class(isc.py.Main).SimpleString("del zzzisabstract")
	quit sc
}

/// Get a %List of members defined by python type satisfying the condition function
/// zw ##class(isc.py.gw.Generator).GetTypeMembers("random.Random", .c), c
ClassMethod GetTypeMembers(type, condition As %String, Output elements As %List) As %Status
{
	set elements = ""
	set sc = ##class(isc.py.Main).SimpleString("zzzmembers = zzzgetmembers(" _ type _ ", " _ condition _ ")", "zzzmembers",, .zzzmembers)
	quit:$$$ISERR(sc) sc
	
	set sc = ##class(isc.py.Main).SimpleString("del zzzmembers")
	quit:$$$ISERR(sc) sc
	
	set obj = [].%FromJSON(zzzmembers)
	
	set iterator = obj.%GetIterator()
	while iterator.%GetNext(.key, .value) {	
		// Class does not implement member, only inherits it.
		set sc = ##class(isc.py.Main).SimpleString("zzzdef = '" _ value _ "' in " _ type _ ".__dict__", "zzzdef", , .zzzdef)
		quit:$$$ISERR(sc)
		set sc = ##class(isc.py.Main).SimpleString("del zzzdef")
		quit:$$$ISERR(sc)
		set zzzdef = ##class(isc.py.util.Converter).PythonToBoolean(zzzdef)
		continue:zzzdef=$$$NO
		
		// Skip inner classes, we're getting them in other passes and they are not methods/props anyway
		set sc = ##class(isc.py.Main).GetVariableType(type _ "." _ value, .memberType)
		continue:memberType="type"
		
		set elements = elements _ $lb(value)
	}

	quit sc
}

/// Get %List of python types belonging to a module  
/// zw ##class(isc.py.gw.Generator).GetModuleTypes("random", .c), c
ClassMethod GetModuleTypes(module, Output types As %List) As %Status
{
	#dim sc As %Status = $$$OK
	set types = ""
	set sc = ##class(isc.py.Main).SimpleString("zzzclasses = zzzgetmembers(" _ module _ ", inspect.isclass)", "zzzclasses",, .zzzclasses)
	quit:$$$ISERR(sc) sc
	
	set obj = [].%FromJSON(zzzclasses)
	
	set iterator = obj.%GetIterator()
	while iterator.%GetNext(.key, .value) {
		set variable = module _ "." _ value
		set sc =  ##class(isc.py.Main).SimpleString("zzztype=('' if " _ variable _ ".__module__ is None or " _ variable _ ".__module__ == str.__class__.__module__ else " _ variable _ ".__module__ + '.') + " _ variable _ ".__name__", "zzztype", , .type)
		quit:$$$ISERR(sc)
		
		// enums? triggered on ssl module.
		set type = $replace(type, "<unknown>", module)
		
		// todo?
		continue:(($l(type, ".")=1) && (module'["builtins"))

		set types = types _ $lb(type)
	}
	
	quit sc
}

/// do ##class(isc.py.gw.Generator).LogException()
Method LogException(level As %Integer, msg As %String, ex As %Exception.AbstractException)
{
	Do ..Log(level, msg _ ". Caught exception: " _ ex.DisplayString())
}

/// do ##class(isc.py.init.Abstract).LogStatus()
Method LogStatus(level As %Integer, msg As %String, sc As %Status)
{
	Do ..Log(level, msg _ ". Completed with " _ $select($$$ISERR(sc):$System.Status.GetErrorText(sc), 1:"success."))
}

/// do ##class(isc.py.init.Abstract).Log()
Method Log(level As %Integer, msg As %String, args...)
{
	Write:level<=..LogLevel $ZDATETIME($ZTIMESTAMP, 3, 1) _ " " _ $$$FormatText(msg, args...),!
}

}

