/// Utility to match input against comma-separated string of masks.
Class isc.py.util.Matcher
{

/// Returns $$$YES if input matches at least one element from the list
/// input - string to match
/// list - comma separated list of masks containig * and ?
/// write ##class(isc.py.util.Matcher).MatchOr()
ClassMethod MatchOr(input As %String, list As %String) As %Boolean
{
	set ok = $$$NO
	for pie = 1:1:$length(list,",") {
		set mask = $piece(list,",",pie) 
		if mask'="",..Match(input,mask) {
			set ok = $$$YES
		}
	}
	quit ok
}

/// Returns $$$YES if input matches all elements from the list
/// input - string to match
/// list - comma separated list of masks containig * and ?
/// write ##class(isc.py.util.Matcher).MatchAnd()
ClassMethod MatchAnd(input As %String, list As %String) As %Boolean
{
	set ok = $$$YES 
	for pie = 1:1:$length(list,",") {
		set mask = $piece(list,",",pie) 
		if mask'="",'..Match(input,mask) {
			set ok = $$$NO
		}
	}
 	quit ok
}

/// Returns $$$YES if input matches the mask
/// write ##class(isc.py.util.Matcher).Match()
ClassMethod Match(input As %String, mask As %String) As %Boolean [ CodeMode = expression ]
{
input?@..MaskToPattern(mask)
}

/// Translate mask into a pattern
/// write ##class(isc.py.util.Matcher).MaskToPattern()
ClassMethod MaskToPattern(mask As %String) As %String
{
	set pattern = ""
	set char = "" 
	for pos = 1:1:$length(mask) {
		set curChar = $extract(mask, pos)
		if curChar = "*" {
			set pattern = pattern _ $select(char="":"", 1:"1"""_char_"""") _ ".E"
			set char = ""
		} elseif curChar = "?" {
			set pattern = pattern _ $select(char="":"", 1:"1"""_char_"""") _ "1E"
			set char = ""
		} else {
			set char = char _ curChar
		}
	}
	set pattern = pattern _ $select(char="":"", 1:"1"""_char_"""")
	quit pattern
}

}

