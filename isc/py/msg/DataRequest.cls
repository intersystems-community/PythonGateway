/// Common properties for Data transfer IRIS -> Python
Class isc.py.msg.DataRequest [ Abstract ]
{

/// Python variable to set
Property Variable As %String [ Required ];

/// Variable type (Currently supported: dataframe (pandas dataframe) and list.
/// Pandas automatically imported if required.
Property Type As %String(VALUELIST = ",dataframe,list") [ InitialExpression = "list", Required ];

/// Namespace in which to execute the query.
/// 'isc.py' package must be available in this namespace
Property Namespace As %String [ InitialExpression = {$namespace}, Required ];

}

