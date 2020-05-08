/// Execute SQL Query in the current process
Class isc.py.msg.SQLRequest Extends Ens.Request
{

/// Query to execute, in a form of
/// - SQL Query
/// - Class:Query
/// - Class:XData
Property Query As %VarString;

Property Args As list Of %String;

}

