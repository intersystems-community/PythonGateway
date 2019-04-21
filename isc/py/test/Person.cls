Class isc.py.test.Person Extends (%Persistent, %Populate)
{

Property Name As %String;

Property DOB As %Date(MINVAL = 47117);

Property TS As %TimeStamp(MINVAL = "1970-01-01 00:00:00");

Property RandomTime As %Time;

Property AgeYears As %Integer;

Property AgeDecimal As %Decimal(SCALE = 2);

Property AgeDouble As %Double(SCALE = 4);

Property Bool As %Boolean;

/// do ##class(isc.py.test.Person).Test()
ClassMethod Test(count As %Integer = 0)
{
	if count {
		do ..%KillExtent()
		do ..Populate(count,,,,$$$NO)
	}
	
	write "Global structure:",!
	zw ^isc.py.test.PersonD(1)
	
	// Import now so it does not affect timings
	set sc = ##class(isc.py.Main).ImportModule("pandas")
	write:$$$ISERR(sc) $System.Status.GetErrorText(sc)

	// All the ways to transfer data
	set query = "SELECT * FROM isc_py_test.Person"
	set class = "isc.py.test.Person"
	set table = "isc_py_test.Person"
	set global = "isc.py.test.PersonD"
	
	// Common arguments
	set variable = "df"
	set type = "dataframe"
	set start = 1
	set end = $select(count>0:count, 1: $g(^isc.py.test.PersonD, 1))

	// Approach 0: ExecuteGlobal without arguments
	set t1 = $zh
	set sc = ##class(isc.py.Main).ExecuteGlobal(global, variable _ 0, type)
	write:$$$ISERR(sc) $System.Status.GetErrorText(sc)
	set t2 = $zh
	write !,"global auto time: ", t2-t1,!
	write ##class(isc.py.util.BPEmulator).DescribeDataframe(variable _ 0),!
	
	
	// Approach 1: ExecuteGlobal with arguments	
	// for global transfer labels are not calculated automatically
	set labels = $lb("globalKey", "Name", "DOB", "TS", "RandomTime", "AgeYears", "AgeDecimal", "AgeDouble", "Bool")

	// mask is 1 element shorter because "globalKey" is global subscript label
	// Note: mask MUST be the same length or greater than longest $lb value. 
	// If you want to skip elements at the end just fill mask with "-"
	// Here we want to skip %%CLASSNAME field
	set mask = "-+dmt+++b"
	
	set t1 = $zh
	set sc = ##class(isc.py.Main).ExecuteGlobal(global, variable _ 1, type, start, end, mask, labels)
	write:$$$ISERR(sc) $System.Status.GetErrorText(sc)
	set t2 = $zh
	write !,"global time: ", t2-t1,!
	write ##class(isc.py.util.BPEmulator).DescribeDataframe(variable _ 1),!

	// Approach 2: ExecuteClass
	set t1 = $zh
	set sc = ##class(isc.py.Main).ExecuteClass(class, variable _ 2, type, start, end)
	write:$$$ISERR(sc) $System.Status.GetErrorText(sc)
	set t2 = $zh
	write !,"class time: ", t2-t1,!
	write ##class(isc.py.util.BPEmulator).DescribeDataframe(variable _ 2),!
	
	// Approach 3: ExecuteTable
	set t1 = $zh
	set sc = ##class(isc.py.Main).ExecuteTable(table, variable _ 3, type, start, end)
	write:$$$ISERR(sc) $System.Status.GetErrorText(sc)
	set t2 = $zh
	write !,"table time: ", t2-t1,!
	write ##class(isc.py.util.BPEmulator).DescribeDataframe(variable _ 3),!
	
	// Approach 4: ExecuteTable
	set t1 = $zh
	set sc = ##class(isc.py.Main).ExecuteQuery(query, variable _ 4, type)
	write:$$$ISERR(sc) $System.Status.GetErrorText(sc)
	set t2 = $zh
	write !,"query time: ", t2-t1,!
	write ##class(isc.py.util.BPEmulator).DescribeDataframe(variable _ 4),!
}

Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>DOB</Value>
</Value>
<Value name="4">
<Value>TS</Value>
</Value>
<Value name="5">
<Value>RandomTime</Value>
</Value>
<Value name="6">
<Value>AgeYears</Value>
</Value>
<Value name="7">
<Value>AgeDecimal</Value>
</Value>
<Value name="8">
<Value>AgeDouble</Value>
</Value>
<Value name="9">
<Value>Bool</Value>
</Value>
</Data>
<DataLocation>^isc.py.test.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^isc.py.test.PersonD</IdLocation>
<IndexLocation>^isc.py.test.PersonI</IndexLocation>
<StreamLocation>^isc.py.test.PersonS</StreamLocation>
<Type>%Library.CacheStorage</Type>
}

}

