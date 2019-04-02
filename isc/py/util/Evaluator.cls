/// Evaluate strings
Class isc.py.util.Evaluator
{

/// Evaluate a string with expressions:
/// ${class:method:arg1:...:argN} - execute method
/// #{expr} - execute ObjectScript code
/// write ##class(isc.py.util.Evaluator).Evaluate("123 #{2+3} ${%PopulateUtils:Integer:1:100}")
ClassMethod Evaluate(expr As %String) As %String
{
	#dim sc As %Status = $$$OK
	set result = expr

	// First, let's evaluate ${} expressions
	$$$TOE(sc, ..EvalMethods(expr, .result))
	
	// Next, let's evaluate #{} expressions
	$$$TOE(sc, ..EvalOS(result, .result))
	
	quit result
}

/// Evaluate ${} expressions
ClassMethod EvalMethods(expr As %String, Output result As %String) As %Status
{
	quit ..EvalToken(expr, "$", "EvalMethod", .result)
}

/// Evaluate #{} expressions
ClassMethod EvalOS(expr As %String, Output result As %String) As %Status
{
	quit ..EvalToken(expr, "#", "EvalCode", .result)
}

/// Evaluate X{} expressions
ClassMethod EvalToken(expr As %String, type As %String, function As %String, Output result As %String) As %Status
{
	#dim sc As %Status = $$$OK
	set result=expr
	while (1) {
		set p = $find(result, type _ "{")
		quit:'p
		
		set q = $find(result, "}", p)
		quit:'q
		
		// Grab the token
		set token = $extract(result, p, q-($l(type)+1))
		set value = $classmethod(, function, token)
	
		// Insert the new value
		set result = $extract(result, 1, p-3) _ $g(value) _ $extract(result, q, $l(result))
	}
	quit sc
}

/// Evaluate method: class:method:arg1:...:argN
ClassMethod EvalMethod(code As %String = "") As %String
{
	set result = ""
	set length = $l(code, ":")
	
	if length<2 {
		throw ##class(%Exception.General).%New("<EVALUATE>", code)
	} else {
		for i=3:1:length {
			set args(i-2) = $p(code, ":", i)
		}
		set args = length - 2
		set result = $classmethod($p(code, ":"), $p(code, ":", 2), args...)
	}

	quit result
}

/// Evaluate an ObjectScript expression
ClassMethod EvalCode(code As %String) As %String
{
	quit @code
}

}

