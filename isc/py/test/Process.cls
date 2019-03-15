/// Sample process 
Class isc.py.test.Process Extends (Ens.BusinessProcessBPL, isc.py.ens.ProcessUtils) [ DependsOn = isc.py.ens.ProcessUtils ]
{

/// Бизнес-операция, запускающая ожидание поступления изменений объекта
Property ConnectionType As %String(MAXLEN = 4, VALUELIST = ",RAW,JDBC,ODBC") [ InitialExpression = "RAW" ];

Parameter SETTINGS = "ConnectionType:Basic";

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.Request' response='Ens.Response' height='2000' width='2000' >
<sequence xend='200' yend='1500' >
<call name='Import pandas' target='isc.py.ens.Operation' async='1' xpos='200' ypos='250' >
<annotation><![CDATA[import pandas as pd]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Import pandas&quot;)" action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' />
</call>
<sync name='Wait for import' calls='Import pandas' type='all' xpos='200' ypos='350' />
<switch name='Get Data' xpos='200' ypos='450' xend='200' yend='700' >
<case condition='process.ConnectionType="RAW"' name='RAW' >
<call name='RAW' target='isc.py.ens.Operation' async='1' xpos='335' ypos='600' >
<annotation><![CDATA[SELECT * FROM isc_py_test.CannibalizationData]]></annotation>
<request type='isc.py.msg.QueryRequest' >
<assign property="callrequest.Query" value="process.GetAnnotation(&quot;RAW&quot;)" action="set" />
<assign property="callrequest.Variable" value="&quot;Data&quot;" action="set" />
<assign property="callrequest.Type" value="&quot;dataframe&quot;" action="set" />
</request>
<response type='Ens.Response' />
</call>
</case>
<case condition='process.ConnectionType="JDBC"' name='JDBC' >
<call name='JDBC' target='isc.py.ens.Operation' async='1' xpos='605' ypos='600' >
<annotation><![CDATA[import jaydebeapi
cnxn=jaydebeapi.connect("com.intersystems.jdbc.IRISDriver","jdbc:IRIS://localhost:51773/Python",  ["dev", "123"], "/InterSystems/IRIS/dev/java/lib/JDK18/intersystems-jdbc-3.0.0.jar")
Data=pd.read_sql('SELECT * FROM isc_py_test.CannibalizationData',cnxn)
cnxn.close()]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;JDBC&quot;)" action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' />
</call>
</case>
<case condition='process.ConnectionType="ODBC"' name='ODBC' >
<call name='ODBC' target='isc.py.ens.Operation' async='1' xpos='875' ypos='600' >
<annotation><![CDATA[import pyodbc
cnxn=pyodbc.connect(('DSN=ENSEMBLE(PYTHON);UID=dev;PWD=123'),autocommit=True)
Data=pd.read_sql('SELECT * FROM isc_py_test.CannibalizationData',cnxn)
cnxn.close()]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;ODBC&quot;)" action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' />
</call>
</case>
<default/>
</switch>
<sync name='Wait for data' calls='RAW,ODBC,JDBC' type='any' xpos='200' ypos='800' />
<call name='Correlation Matrix: Tabular' target='isc.py.ens.Operation' async='1' xpos='200' ypos='900' >
<annotation><![CDATA[Data0=Data.drop(['WEEK'],axis=1)
corrmat=Data0.corr()
corrmat.columns.name='CATEGORY'
result=corrmat.to_string()]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Variables" value="&quot;result&quot;" action="set" />
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Correlation Matrix: Tabular&quot;)" action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' />
</call>
<sync name='Wait Correlation Matrix: Tabular' calls='Correlation Matrix: Tabular' type='all' xpos='200' ypos='1000' />
<call name='Correlation Matrix: Graph' target='isc.py.ens.Operation' async='1' xpos='200' ypos='1100' >
<annotation><![CDATA[import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
f=plt.figure()
sns.heatmap(corrmat,xticklabels=corrmat.columns,yticklabels=corrmat.columns)
plt.title('Correlation analysis of category sales volumes (by year/month)')
f.savefig(r'C:\InterSystems\Ensemble\mgr\Temp\SHOWCASE004USE02.png')
plt.close(f)]]></annotation>
<request type='isc.py.msg.ExecutionRequest' >
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Correlation Matrix: Graph&quot;)" action="set" />
</request>
<response type='isc.py.msg.ExecutionResponse' />
</call>
<sync name='Wait Correlation Matrix: Graph' calls='Correlation Matrix: Graph' type='all' xpos='200' ypos='1200' />
<call name='Save Context' target='isc.py.ens.Operation' async='1' xpos='200' ypos='1300' >
<request type='isc.py.msg.SaveRequest' />
<response type='Ens.StringResponse' />
</call>
<sync name='Wait: Save Context' calls='Save Context' type='all' xpos='200' ypos='1400' />
</sequence>
</process>
}

Storage Default
{
<Data name="ProcessDefaultData">
<Subscript>"Process"</Subscript>
<Value name="1">
<Value>ConnectionType</Value>
</Value>
</Data>
<DefaultData>ProcessDefaultData</DefaultData>
<Type>%Library.CacheStorage</Type>
}

}

