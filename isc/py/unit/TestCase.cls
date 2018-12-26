Class isc.py.unit.TestCase Extends %UnitTest.TestCase
{

Method OnBeforeAllTests() As %Status
{
	do ##class(isc.py.Callout).Setup()
	quit $$$OK
}

Method TestBasic()
{
	set random = ##class(isc.py.Callout).GetRandom()
	do $$$AssertTrue(random<1, "GetRandom works")
}

Method TestBasicSimpleString()
{
	set random = ##class(isc.py.Callout).SimpleStringFull()
	do $$$AssertTrue(random<1, "SimpleStringFull works")
}

Method TestSimpleString()
{
	do ##class(isc.py.Callout).Finalize()
	set random = ##class(isc.py.Callout).SimpleString()
	do $$$AssertTrue(random<1, "SimpleString works")

	do ##class(isc.py.Callout).SimpleString("y=1")
	set y = ##class(isc.py.Callout).SimpleString(, "y")
	do $$$AssertEquals(y, 1, "Context is persisted")
	
	do ##class(isc.py.Callout).Finalize()
	
	set y = ##class(isc.py.Callout).SimpleString(, "y")
	do $$$AssertEquals(y, "", "Context successfully flushed")
}

Method TestLimit()
{
	do ##class(isc.py.Callout).Finalize()
	
	do ##class(isc.py.Callout).SimpleString("str1000=''.join('A' for _ in range(1000))")	

	for limit = 32767,135108,$$$MaxStringLength {
		set quotient = limit\1000
		set modulus = limit#1000
		set str = ##class(isc.py.Callout).SimpleString("str=''.join(str1000 for i in range("_quotient_")) + str1000[:" _ modulus _ "]", "str")	
		do $$$AssertEquals($l(str), limit, "Returned " _ limit _ " characters") 
	}

	try {
		set limit = $$$MaxStringLength + 1
		set quotient = limit\1000
		set modulus = limit#1000
		set str = ##class(isc.py.Callout).SimpleString("str=''.join(str1000 for i in range("_quotient_")) + str1000[:" _ modulus _ "]", "str")
	} catch ex {
		do $$$AssertEquals(ex.Name, "<FUNCTION>" , "Correctly failed to pass " _ limit _ " characters")
	}
	
	do $$$AssertTrue($isObject($g(ex)), "If failed then we managed to pass more characters than in character limit")
}

Method TestPassSpeedIn()
{
	set setChars = 6
	set limit = 32767 - setChars
	set str = $tr($j("", limit), " ", "A")
	
	set rounds = 295
	set start = $zh
	for i = 1:1:rounds {
		do ##class(isc.py.Callout).SimpleString("str='" _ str _ "'")
	}
	set end = $zh
	
	set time = end - start
	set megabytes = $fnumber((limit+setChars)*rounds/(1024**2), "", 2)
	set speed = $fnumber(megabytes/time, "", 2)
	
	do $$$LogMessage($$$FormatText("Passed in %1 Mb in %2 sec. Speed: %3 Mb/sec.", megabytes, time, speed))
}

Method TestPassSpeedOut()
{
	set limit = $$$MaxStringLength
	set quotient = limit\1000
	set modulus = limit#1000
	do ##class(isc.py.Callout).SimpleString("str=''.join(str1000 for i in range("_quotient_")) + str1000[:" _ modulus _ "]", "str")

	set rounds = 295
	set start = $zh
	for i = 1:1:rounds {
		set str = ##class(isc.py.Callout).SimpleString(, "str")
		kill str
	}
	set end = $zh
	
	set time = end - start
	set megabytes = $fnumber(limit*rounds/(1024**2), "", 2)
	set speed = $fnumber(megabytes/time, "", 2)
	
	do $$$LogMessage($$$FormatText("Passed out %1 Mb in %2 sec. Speed: %3 Mb/sec.", megabytes, time, speed))
}

Method TestSetCallSpeed()
{
	do ##class(isc.py.Callout).SimpleString("str=''")
	set rounds = 100000
	set start = $zh
	for i = 1:1:rounds {
		do ##class(isc.py.Callout).SimpleString("str=" _ i)
	}
	set end = $zh
	
	set time = end - start
	set speed = $fnumber(rounds/time, "", 2)
	
	do $$$LogMessage($$$FormatText("Called python %1 times in %2 sec. Speed: %3 calls/sec.", rounds, time, speed))
}

Method TestUnicode()
{
	set unicode = "ПРИВЕТ"
	set result = ##class(isc.py.Callout).SimpleString("result='" _ unicode _ "'", "result")
	do $$$AssertEquals(unicode, result, "Passing unicode characters works")
}

}

