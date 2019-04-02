Class isc.py.gw.Generator Extends %RegisteredObject
{

Property Debug As %Boolean [ InitialExpression = {$$$YES} ];

/// Already done
Property GeneratedClassList As %List;

/// Work to do
Property ClassList As %List;

Property Package As %String;

Property Inspect As %String [ InitialExpression = "inspect" ];

Property Module As %String;

/// do ##class(isc.py.gw.Generator).Test()
ClassMethod Test()
{
	set package = "py"
	do $system.OBJ.DeletePackage(package)
	
	set obj = ..%New()
	set obj.Package = package
	set sc = obj.GenerateModule("random")
	w $System.Status.GetErrorText(sc)
	
	set sc = obj.Compile()
	w $System.Status.GetErrorText(sc)
}

Method Compile()
{
	set irisClasses = $lb(..PythonClassToIRIS(..Module))
	set ptr=0
	while $listnext(..GeneratedClassList, ptr, value) {
		set irisClasses = irisClasses _ $lb(..PythonClassToIRIS(value))
	}

	
	set sc = $system.OBJ.Compile($lts(irisClasses), "cukd")
	quit sc
}

Method GenerateModule(module) As %Status
{
	set sc = ##class(isc.py.init.Generator).Initialize(,..Debug)
	quit:$$$ISERR(sc) sc
	
	set ..Module = module

	set sc = ##class(isc.py.Main).ImportModule(module, .imported, .alias)
	quit:$$$ISERR(sc) sc
	

	
	do ..Log("Generating module: %1 into package: %2", module, ..Package)
	
	set sc = ..GetModuleClasses(module, .classes)
	
	do ..AppendToClassList(classes)

	while $ll(..ClassList)>0 {
		set list = ..ClassList
		set class = $lg(list, *)
		set $li(list, *, *) = ""
		set ..GeneratedClassList = ..GeneratedClassList _ $lb(class)
		set ..ClassList = list
		
		set sc = ..GenerateClass(class)
		quit:$$$ISERR(sc)
		//break	
	}
	quit:$$$ISERR(sc) sc
	
	set sc = ..GenerateClass(module)
	
	quit sc
}

Method GenerateClass(class) As %Status
{
	#dim sc As %Status = $$$OK
	do ..Log("Generating class: %1", class)

	set sc = ..GetInitialClass(class, .classObj)
	quit:$$$ISERR(sc) sc
	
	set sc = ..GetClassMethods(class, .methods)
	quit:$$$ISERR(sc) sc
	
	set ptr=0
	while $listnext(methods, ptr, value) {
		set sc = ..GenerateMethod(class, classObj, value) 
		quit:$$$ISERR(sc)
	}
	quit:$$$ISERR(sc) sc
	
	set sc = classObj.%Save()
	
	quit sc
}

Method GetInitialClass(class As %String, Output classObj As %Dictionary.ClassDefinition) As %Status
{
	#dim sc As %Status = $$$OK
	set irisClass = ..PythonClassToIRIS(class)
	if ##class(%Dictionary.ClassDefinition).%ExistsId(irisClass) {
		set classObj = ##class(%Dictionary.ClassDefinition).%OpenId(irisClass)
	} else {
		set classObj = ##class(%Dictionary.ClassDefinition).%New(irisClass)
	}
	
	do classObj.ProcedureBlockReset()
	
	set sc = ##class(isc.py.Main).SimpleString("zzzdocs=" _ ..Inspect _ ".getdoc(" _ class _ ")", "zzzdocs", , .docs)
	quit:$$$ISERR(sc) sc
	set sc = ##class(isc.py.Main).SimpleString("del zzzdocs")
	set:docs="None" docs = ""
	
	set classObj.Description = "Pyhton class: " _ class _ $$$NL _ $replace(docs, $c(10), $$$NL)
	//set classObj.GeneratedBy = "Python Gateway"
	
	set sc = ##class(isc.py.Main).SimpleString("zzzextends=json.dumps([item.__module__ + '.' + item.__name__ for item in " _ ..Inspect _ ".getmro(" _ class _ ")])", "zzzextends", , .zzzextends)
	// TODO - modules
	if $$$ISERR(sc) {
		set sc = $$$OK
		set classObj.Super = "isc.py.gw.DynamicObject"
	} else {
		set obj = [].%FromJSON(zzzextends)
		
		set extends = ""
		set irisExtends = ""
		set iterator = obj.%GetIterator()
		while iterator.%GetNext(.key, .value) {
			continue:$e(value)="_"
			continue:$l(value, ".")=1
			set:$p(value, ".")="builtins" value = $p(value, ".", 2, *)
			continue:value=class
			set extends = extends _ $lb(value)
			set irisExtends = irisExtends _ $lb(..PythonClassToIRIS(value))
		}
		set classObj.Super = $lg(irisExtends,1,"isc.py.gw.DynamicObject")
		do ..AppendToClassList(extends)
	}
		
	quit sc
}

Method PythonClassToIRIS(class As %String) [ CodeMode = expression ]
{
..Package _ "." _ class
}

Method GenerateMethod(class As %String, classObj As %Dictionary.ClassDefinition, method As %String) As %Status
{
	set sc = ##class(isc.py.Main).GetFunctionInfo(class _ "." _ method, .defined, .type, .docs, .signature, .arguments)
	quit:$$$ISERR(sc) sc
	
	set methodObj = ##class(%Dictionary.MethodDefinition).%New()
	
	set methodObj.Name = method
	set methodObj.parent = classObj
	set methodObj.ClassMethod = $$$YES
	set methodObj.Description = "Signature: " _ signature _ $$$NL _ "Type: " _ type _ $$$NL _ $replace(docs, $c(10), $$$NL) _ $$$NL _ "write ##class(" _ classObj.Name _ ")." _ $case($zname(method,6), 1:method, :"""" _ method _ """") _ "()"
	
	
	// start - calculating sifgnatures
	
	// Method signature
	set irisArgs = ""
	
	// python call signature 
	set callArgs = ""
	
	// Are we currently on first arg
	#dim firstArg As %Boolean = $$$YES
	
	
	if arguments="" {
		set irisArgs = "args..."
		set callArgs = "..%CallArgsToString(args...)"
		if type["method" {
			set methodObj.ClassMethod = $$$NO
		}
	} else {		
		set funcArgObj = [].%FromJSON(arguments)
		
		#dim args As %DynamicArray = funcArgObj.%Get(0)
		#dim varargs As %String = funcArgObj.%Get(1)
		#dim varkw As %String = funcArgObj.%Get(2)
		#dim defaults As %DynamicArray = funcArgObj.%Get(3)
		#dim kwonlyargs As %DynamicArray = funcArgObj.%Get(4)
		#dim kwonlydefaults As %DynamicArray = funcArgObj.%Get(5)
		
		// Remove self argument if it's a method or a constructor function
		if ((type["method") || ($isObject(args) && (args.%Get(0)="self"))) {
			set methodObj.ClassMethod = $$$NO
			do args.%Remove(0)
		} 
		
		#dim posCount As %Integer = $case($isObject(args), $$$YES: args.%Size(), :0)
		#dim kwCount As %Integer = $case($isObject(kwonlyargs), $$$YES: kwonlyargs.%Size(), :0)
		#dim hasArgs As %Boolean = (varargs'="")
		#dim hasKWArgs As %Boolean = (varkw'="")
	 
	 	
	 	
		
		set iterator = args.%GetIterator()
		while iterator.%GetNext(.key, .value) {
			set irisArgs = irisArgs _ $case(firstArg, $$$YES:"", :", ") _ ..VarNameToIRIS(value)
			set callArgs = callArgs _ $case(firstArg, $$$YES:"", :"_"",""_") _ "..%EscapeArg(" _ ..VarNameToIRIS(value) _ ")"
			set firstArg = $$$NO
			
			
			//set default = $case($isObject($g(defaults)), $$$YES:defaults.%Get(key), :"")
			//set:default'="" irisArgs = irisArgs _ "=" _ default
		}
		
		if hasArgs {
			set irisArgs = irisArgs _ $case(firstArg, $$$YES:"", :", ") _ ..VarNameToIRIS(varargs)
			set callArgs = callArgs _ $case(firstArg, $$$YES:"", :"_"",""_") _ "..%ArgsToString(" _ ..VarNameToIRIS(varargs) _ ")"
			set firstArg = $$$NO
		}
		
		set iterator = kwonlyargs.%GetIterator()
		while iterator.%GetNext(.key, .value) {			
			set irisArgs = irisArgs _ $case(firstArg, $$$YES:"", :", ") _ ..VarNameToIRIS(value)		
			set callArgs = callArgs _ $case(firstArg, $$$YES:"", :"_"",""_") _ """" _ value _ "=""_..%EscapeArg(" _ ..VarNameToIRIS(value) _ ")"
			set firstArg = $$$NO

			//set default = $case($isObject($g(kwonlydefaults)), $$$YES:kwonlydefaults.%Get(key), :"")
			//set:default'="" irisArgs = irisArgs _ "=" _ default
		}
		
		if hasKWArgs {
			set irisArgs = irisArgs _ $case(firstArg, $$$YES:"", :", ") _ ..VarNameToIRIS(varkw)
			set callArgs = callArgs _ $case(firstArg, $$$YES:"", :"_"",""_") _ "..%KWArgsToString(" _ ..VarNameToIRIS(varkw) _ ")"
			set firstArg = $$$NO
		}
	}
	// end - calculating signatures
	
	
	set:class=..Module methodObj.ClassMethod = $$$YES

	// start - calculating caller obj on Python side
	if methodObj.ClassMethod {
		set caller =  class _ "." _ method
	} else {
		set caller = """ _ ..%Variable _ """
	}
	// end - calculating caller obj on Python side
	
	if irisArgs'="" {
		do methodObj.Implementation.WriteLine($c(9) _ "$$$TOE(sc, ##class(isc.py.Main).SimpleString(""zzzresult = " _ caller _ "(""_" _ callArgs  _ "_"")"", ""zzzresult"", , .zzzresult))") //$lts(irisArgs, "_"",""_")
	} else {
		do methodObj.Implementation.WriteLine($c(9) _ "$$$TOE(sc, ##class(isc.py.Main).SimpleString(""zzzresult = " _ caller _ "()"", ""zzzresult"", , .zzzresult))")
	}
	do methodObj.Implementation.WriteLine($c(9) _ "quit zzzresult")
	set methodObj.FormalSpec = irisArgs
	
	quit sc
}

ClassMethod VarNameToIRIS(string) As %String [ CodeMode = expression ]
{
$tr(string, "_")
}

Method AppendToClassList(classes As %List)
{
	set ptr=0
	while $listnext(classes, ptr, value) {
		if (($lf(..GeneratedClassList, value)=0) && ($lf(..ClassList, value)=0)) {
			set ..ClassList = ..ClassList _ $lb(value)
		}
	}
}

/// zw ##class(isc.py.gw.Generator).GetClassMethods("random.Random", .c), c
ClassMethod GetClassMethods(class, Output methods As %List) As %Status
{
	set methods = ""
	set sc = ##class(isc.py.Main).SimpleString("zzzmethods = zzzgetmembers(" _ class _ ", callable)", "zzzmethods",, .zzzmethods)
	quit:$$$ISERR(sc) sc
	
	set obj = [].%FromJSON(zzzmethods)
	
	set iterator = obj.%GetIterator()
	while iterator.%GetNext(.key, .value) {
		//set variable = module _ "." _ value
		//set sc =  ##class(isc.py.Main).SimpleString("", "zzztype", , .type)
		//quit:$$$ISERR(sc)
		// todo get only things defined in the class
		//continue:$e(value)="_"
		
		// Class does not implement the method, only inherits it.
		set sc = ##class(isc.py.Main).SimpleString("zzzdef = '" _ value _ "' in " _ class _ ".__dict__", "zzzdef", , .zzzdef)
		quit:$$$ISERR(sc)
		set zzzdef = ##class(isc.py.util.Converter).PythonToBoolean(zzzdef)
		continue:zzzdef=$$$NO
		
		set sc = ##class(isc.py.Main).GetVariableType(class _ "." _ value, .type)
		continue:type="type"
		
		set methods = methods _ $lb(value)
	}
	quit sc
}

/// zw ##class(isc.py.gw.Generator).GetModuleClasses("random", .c), c
ClassMethod GetModuleClasses(module, Output classes As %List) As %Status
{
	set classes = ""
	set sc = ##class(isc.py.Main).SimpleString("zzzclasses = zzzgetmembers(" _ module _ ", inspect.isclass)", "zzzclasses",, .zzzclasses)
	quit:$$$ISERR(sc) sc
	
	set obj = [].%FromJSON(zzzclasses)
	
	set iterator = obj.%GetIterator()
	while iterator.%GetNext(.key, .value) {
		set variable = module _ "." _ value
		set sc =  ##class(isc.py.Main).SimpleString("zzztype=('' if " _ variable _ ".__module__ is None or " _ variable _ ".__module__ == str.__class__.__module__ else " _ variable _ ".__module__ + '.') + " _ variable _ ".__name__", "zzztype", , .type)
		quit:$$$ISERR(sc)
		
		continue:$l(type, ".")=1
		set:$p(type, ".")="builtins" type = $p(type, ".", 2, *)

		set classes = classes _ $lb(type)
	}
	quit sc
}

/// do ##class(isc.py.gw.Generator).LogException()
Method LogException(msg As %String, ex As %Exception.AbstractException)
{
	Do ..Log(msg _ ". Caught exception: " _ ex.DisplayString())
}

/// do ##class(isc.py.init.Abstract).LogStatus()
Method LogStatus(msg As %String, sc As %Status)
{
	Do ..Log(msg _ ". Completed with " _ $select($$$ISERR(sc):$System.Status.GetErrorText(sc), 1:"success."))
}

/// do ##class(isc.py.init.Abstract).Log()
Method Log(msg As %String, args...)
{
	Write:..Debug $ZDATETIME($ZTIMESTAMP, 3, 1) _ " " _ $$$FormatText(msg, args...),!
}

}

