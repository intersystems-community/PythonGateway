/// Generate IRIS classes from Pyhton types 
Class isc.py.gw.Generator Extends %RegisteredObject
{

/// Display logging info. Increasing the number shows more messages.
/// -1 display nothing
/// 0 - display modules info
/// 1 - display types info
/// 2 - display methods/properties info
Property LogLevel As %Integer [ InitialExpression = 1 ];

/// Already done python types
Property GeneratedTypeList As %List;

/// Work to do - python types
Property TypeList As %List;

/// Created IRIS classes
Property ClassList As %List;

/// Base pachage for generated classes
Property Package As %String [ InitialExpression = "py" ];

/// Inspect alias
Property Inspect As %String [ InitialExpression = "inspect" ];

/// Module alias we're currently importing
Property Module As %String;

/// Base class for all python classes
Property BaseClass As %String [ InitialExpression = "isc.py.gw.DynamicObject" ];

/// List of modules loaded in memory
Property ImportedModules As %List;

/// do ##class(isc.py.gw.Generator).Test()
ClassMethod Test(modules As %List = {$lb("builtins","random")})
{
	set package = "py"
	do $system.OBJ.DeletePackage(package)
	
	set obj = ..%New()
	set obj.Package = package
	
	for i=1:1:$ll(modules) {
		set sc = obj.GenerateModule($lg(modules, i))
		w $System.Status.GetErrorText(sc)
	}
	set sc = obj.Compile()
	w $System.Status.GetErrorText(sc)
}

/// Compile all generated classes
Method Compile()
{
	set irisClasses = ""
	set ptr=0
	
	if ..LogLevel>0 {
		set displayFlags = "/display=all"
	} else {
		set displayFlags = "/checkuptodate=expandedonly /displaylog=0 /displayerror=0"
	}
	
	set sc = $system.OBJ.Compile($lts(..ClassList), "cuks /checkuptodate=expandedonly " _ displayFlags)
	quit sc
}

/// Generate module
Method GenerateModule(module) As %Status
{
	set sc = ##class(isc.py.init.Generator).Initialize(,(..LogLevel>0))
	quit:$$$ISERR(sc) sc
	
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
		set ..GeneratedTypeList = ..GeneratedTypeList _ $lb(type)
		
		set sc = ..CheckImportedModule(type)
		quit:$$$ISERR(sc)
		
		set sc = ..GenerateClass(type)
		quit:$$$ISERR(sc)
		
		set ..ClassList = ..ClassList _ $lb(..TypeToClass(type))
		//break	
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
	
	set ptr=0
	while $listnext(methods, ptr, method) {
		set sc = ..GenerateMethod(type, classObj, method) 
		quit:$$$ISERR(sc)
	}
	quit:$$$ISERR(sc) sc
	
	set sc = ..GetTypeMembers(type, "zzzuncallable", .properties)
	quit:$$$ISERR(sc) sc
	
	set ptr=0
	while $listnext(properties, ptr, property) {
		set sc = ..GenerateProperty(classObj, property) 
		quit:$$$ISERR(sc)
	}
	quit:$$$ISERR(sc) sc
	
	set sc = classObj.%Save()
	
	quit sc
}

/// Get class object. Populates docs and inheritance.
Method GetInitialClass(type As %String, Output classObj As %Dictionary.ClassDefinition) As %Status
{
	#dim sc As %Status = $$$OK
	set class = ..TypeToClass(type)
	if ##class(%Dictionary.ClassDefinition).%ExistsId(class) {
		set classObj = ##class(%Dictionary.ClassDefinition).%OpenId(class)
	} else {
		set classObj = ##class(%Dictionary.ClassDefinition).%New(class)
	}
	
	do classObj.ProcedureBlockReset()
	
	set sc = ..IsAbstract(type, .isAbstract)
	quit:$$$ISERR(sc) sc
	set classObj.Abstract = isAbstract
	
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
			// todo classes with underscores, i.e. random._Random and random.Random 
			continue:$e(value)="_"
			
			// todo replace with __builtins__
			set:$p(value, ".")="builtins" value = $p(value, ".", 2, *)
			continue:value=type
			set extends = extends _ $lb(value)
			set irisExtends = irisExtends _ $lb(..TypeToClass(value))
		}
		set classObj.Super = $lg(irisExtends, 1, ..BaseClass)
		do ..AppendToTypeList(extends)
	}
		
	quit sc
}

/// Generate property code.
Method GenerateProperty(classObj As %Dictionary.ClassDefinition, property As %String) As %Status
{
	#dim sc As %Status = $$$OK
	do ..Log(2, "Property: %1", property)
	#dim propIndex As %Integer = classObj.Properties.FindObjectId(classObj.Name _ "||" _ property)
	if (+propIndex > 0) {
		set propObj = classObj.Properties.GetAt(propIndex)
	} else {
		set propObj = ##class(%Dictionary.PropertyDefinition).%New()
		set propObj.Name = property
		set propObj.parent = classObj
		set propObj.Type = "%String"
	}
	
	// Property getter
	#dim getIndex As %Integer = classObj.Methods.FindObjectId(classObj.Name _ "||" _ property _ "Get")
	if getIndex="" {
		set getObj = ##class(%Dictionary.MethodDefinition).%New()
		set getObj.Name = property _ "Get"
		set getObj.parent = classObj
		set getObj.CodeMode = "expression"
		do getObj.Implementation.WriteLine($c(9) _ "..%DispatchGetProperty(""" _ property _ """)")
	}	

	// Property setter
	#dim setIndex As %Integer = classObj.Methods.FindObjectId(classObj.Name _ "||" _ property _ "Set")
	if setIndex="" {
		set setObj = ##class(%Dictionary.MethodDefinition).%New()
		set setObj.Name = property _ "Set"
		set setObj.parent = classObj
		set setObj.CodeMode = "expression"
		set setObj.FormalSpec = "val"
		do setObj.Implementation.WriteLine($c(9) _ "..%DispatchSetProperty(""" _ property _ """, val)")
		set setObj.ReturnType = "%Status"
	}	
	quit sc
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
	if ((type'=..Module) && ((..Module = "__builtins__") || ($l(type,".")=1))) {
		set type = "builtins." _ type	
	}
	quit $zstrip($tr(..Package _ "." _ type, "_", "."),"=>P")
}

/// Translate method argument names from Python to IRIS.
ClassMethod VarNameToIRIS(string) As %String [ CodeMode = expression ]
{
$tr(string, "_")
}

/// Generate method code.
Method GenerateMethod(type As %String, classObj As %Dictionary.ClassDefinition, method As %String) As %Status
{
	#dim sc As %Status = $$$OK
	do ..Log(2, "Method: %1", method)
	set sc = ##class(isc.py.Main).GetFunctionInfo(type _ "." _ method, .defined, .methodType, .docs, .signature, .arguments)
	quit:$$$ISERR(sc) sc
	
	set name = $case(method, "__init__":"%OnNew", :method)
	
	#dim methodIndex As %Integer = classObj.Methods.FindObjectId(classObj.Name _ "||" _ name)
	if methodIndex = "" {
		set methodObj = ##class(%Dictionary.MethodDefinition).%New()
		
		set methodObj.Name = name
		set methodObj.parent = classObj
		set methodObj.Description = "Signature: " _ signature _ $$$NL _ "Type: " _ methodType _ $$$NL _ $replace(docs, $c(10), $$$NL) _ $$$NL
		
		set sc = ..IsAbstract(type _ "." _ method, .isAbstract)
		quit:$$$ISERR(sc) sc
		set methodObj.Abstract = isAbstract
		
		// Is it class or object method? - Start
		set methodObj.ClassMethod = $$$YES
		set:methodType["method" methodObj.ClassMethod = $$$NO
		// Is it class or object method? - Ens
		// Not really the end
		
		// start - calculating signatures
		if arguments="" {
			set formalSpec = "args..."
			set callArgs = "..%CallArgsToString(args...)"
		} else {
			#dim funcArgObj As %DynamicArray = [].%FromJSON(arguments)
			// If it has self arg, it's probably an instance method
			if (($isObject(funcArgObj.%Get(0)) && (funcArgObj.%Get(0).%Get(0)="self"))) {
				set methodObj.ClassMethod = $$$NO
			}

			do ..GenereateMethodSignature(funcArgObj, .formalSpec, .callArgs)
		}	
		// end - calculating signatures
		
		// Module methods can always be called
		set:type=..Module methodObj.ClassMethod = $$$YES
			
		do ..GenerateMethodBody(methodObj, type, method, formalSpec, callArgs)
		set methodObj.Description = methodObj.Description _  ..GenerateCall(classObj.Name, methodObj.Name, methodObj.ClassMethod) 
	}
	quit sc
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
	
	if method = "%OnNew" {
		set args = "(,"""")"
	} else {
		set args ="()"
	}
	
	set call = command _ objCall _ "." _ methodCall _ args
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
		set callArgs = callArgs _ $case(firstArg, $$$YES:"", :"_"",""_") _ """" _ value _ "=""_..%EscapeArg(." _ ..VarNameToIRIS(value) _ ")"
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
		do ..GenerateOnNewMethodBody(methodObj, formalSpec, callArgs)
	} else {
		do ..GenerateCommonMethodBody(methodObj, class, method, formalSpec, callArgs)
	}
	
	do:methodObj.Abstract methodObj.Implementation.Clear()
}

/// Generate %OnNew method
ClassMethod GenerateOnNewMethodBody(methodObj As %Dictionary.MethodDefinition, formalSpec As %String, callArgs As %String)
{
	set methodObj.ClassMethod = $$$NO
	set methodObj.ReturnType = "%Status"
	set methodObj.FormalSpec = "init:%String=$$$YES,variable:%String" _ $case(formalSpec'="", $$$YES:", ", :"") _ formalSpec 
	
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
	do methodObj.Implementation.WriteLine($c(9,9) _ "set result = $classmethod(..%TypeToClass(type), ""%New"", , variable)")
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
	if $lf(..ImportedModules, module)=0 {
		set sc = ##class(isc.py.Main).ImportModule(module)
		quit:$$$ISERR(sc) sc
		
		do ..AppendImportedModule(module)
	}
	
	quit sc
}

/// Add imported module to ImportedModules property
Method AppendImportedModule(module As %String)
{
	if $lf(..ImportedModules, module)=0 {
			set ..ImportedModules = ..ImportedModules _ $lb(module)
	}
}

/// Append a %List of python types to TypeList.
/// If GeneratedTypeList or TypeList alredy clontain python type it would be skipped.
Method AppendToTypeList(types As %List)
{
	set ptr=0
	while $listnext(types, ptr, type) {
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

/// Get a %List of methods defined by python type satisfying the condition function
/// zw ##class(isc.py.gw.Generator).GetClassMethods("random.Random", .c), c
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
		
		// todo?
		continue:(($l(type, ".")=1) && (module'["builtins"))
		set:$p(type, ".")="builtins" type = $p(type, ".", 2, *)

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

