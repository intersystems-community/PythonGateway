/// Sample process 
Class isc.py.test.Process Extends (Ens.BusinessProcessBPL, isc.py.ens.ProcessUtils)
{

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.Request' response='Ens.Response' height='2000' width='2000' >
<sequence xend='200' yend='650' >
<call name='Correlation Matrix: Tabular' target='isc.py.ens.Operation' async='1' xpos='200' ypos='250' >
<annotation><![CDATA[import pyodbc
import pandas as pd
cnxn=pyodbc.connect(('DSN=ENSEMBLE(PYTHON);UID=dev;PWD=123'),autocommit=True)
y=1
Data=pd.read_sql('SELECT * FROM isc_py_test.CannibalizationData',cnxn)
Data0=Data.drop(['WEEK'],axis=1)
Data0['BRATWURST']=pd.to_numeric(Data0['BRATWURST'])
Data0['CERVELAS']=pd.to_numeric(Data0['CERVELAS'])
Data0['CHARCUTERIE']=pd.to_numeric(Data0['CHARCUTERIE'])
Data0['DAUERFLEISCHWAREN']=pd.to_numeric(Data0['DAUERFLEISCHWAREN'])
Data0['GEFLUEGEL']=pd.to_numeric(Data0['GEFLUEGEL'])
Data0['GERAEUCHERTES_ZUM_KOCHEN']=pd.to_numeric(Data0['GERAEUCHERTES_ZUM_KOCHEN'])
Data0['HACKFLEISCH']=pd.to_numeric(Data0['HACKFLEISCH'])
Data0['INNEREIEN_DIVERSES']=pd.to_numeric(Data0['INNEREIEN_DIVERSES'])
Data0['KALB']=pd.to_numeric(Data0['KALB'])
Data0['KANINCHEN']=pd.to_numeric(Data0['KANINCHEN'])
Data0['LAMM']=pd.to_numeric(Data0['LAMM'])
Data0['MARINADEN']=pd.to_numeric(Data0['MARINADEN'])
Data0['PASTETEN_TERRINEN_STREICHWURST']=pd.to_numeric(Data0['PASTETEN_TERRINEN_STREICHWURST'])
Data0['PFANNENFERTIGES']=pd.to_numeric(Data0['PFANNENFERTIGES'])
Data0['PFERD']=pd.to_numeric(Data0['PFERD'])
Data0['RIND']=pd.to_numeric(Data0['RIND'])
Data0['SALAMI_ROHWURST_AM_STUECK']=pd.to_numeric(Data0['SALAMI_ROHWURST_AM_STUECK'])
Data0['SCHINKEN']=pd.to_numeric(Data0['SCHINKEN'])
Data0['SCHWEIN']=pd.to_numeric(Data0['SCHWEIN'])
Data0['UEBRIGE_BRUEHWURST_STUECK']=pd.to_numeric(Data0['UEBRIGE_BRUEHWURST_STUECK'])
Data0['WIENERLI_KNACKERLI_FRANKFURTERLI']=pd.to_numeric(Data0['WIENERLI_KNACKERLI_FRANKFURTERLI'])
corrmat=Data0.corr()
corrmat.columns.name='CATEGORY'
//PyRun_SimpleString("import sys
//PyRun_SimpleString("orig_stdout=sys.stdout
//PyRun_SimpleString("f=open('C:/IRIS+Python/IRIS+Python_output_model_001.txt','w')
//PyRun_SimpleString("sys.stdout=f
result=corrmat.to_string()
//PyRun_SimpleString("sys.stdout=orig_stdout
//PyRun_SimpleString("f.close()
cnxn.close()
]]></annotation>
<request type='isc.py.ens.Request' >
<assign property="callrequest.Variables" value="&quot;result&quot;" action="set" />
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Correlation Matrix: Tabular&quot;)" action="set" />
</request>
<response type='isc.py.ens.Response' />
</call>
<sync name='Wait Correlation Matrix: Tabular' calls='Correlation Matrix: Tabular' type='all' xpos='200' ypos='350' />
<call name='Correlation Matrix: Graph' target='isc.py.ens.Operation' async='1' xpos='200' ypos='450' >
<annotation><![CDATA[import matplotlib
import matplotlib.pyplot as plt
import seaborn as sns
f=plt.figure()
sns.heatmap(corrmat,xticklabels=corrmat.columns,yticklabels=corrmat.columns)
plt.title('Correlation analysis of category sales volumes (by year/month)')
f.savefig(r'C:\InterSystems\Ensemble\mgr\Temp\SHOWCASE004USE02.png')
plt.close(f)]]></annotation>
<request type='isc.py.ens.Request' >
<assign property="callrequest.Code" value="process.GetAnnotation(&quot;Correlation Matrix: Graph&quot;)" action="set" />
</request>
<response type='isc.py.ens.Response' />
</call>
<sync name='Wait Correlation Matrix: Graph' calls='Correlation Matrix: Graph' type='all' xpos='200' ypos='550' />
</sequence>
</process>
}

Storage Default
{
<Type>%Library.CacheStorage</Type>
}

}

