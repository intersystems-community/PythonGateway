/// Installer for the container release of PythonGateway
Class isc.py.util.Installer
{

XData Install [ XMLNamespace = INSTALLER ]
{
<Manifest>
  <Default Name="NAMESPACE" Value="PYTHON"/>
  <Default Name="DBNAME" Value="${NAMESPACE}"/>
  <Default Name="SOURCESPATH" Dir='#{$system.Util.GetEnviron("SRC_DIR")}' />
  <Default Name="RESOURCE" Value="%DB_${DBNAME}" /> 
  <Namespace Name="${NAMESPACE}" Code="${DBNAME}CODE" Data="${DBNAME}DATA" Create="yes" Ensemble="1">
    <Configuration>
      <Database Name="${DBNAME}CODE" Dir="${MGRDIR}${DBNAME}CODE" Create="yes" Resource="${RESOURCE}"/>
      <Database Name="${DBNAME}DATA" Dir="${MGRDIR}${DBNAME}DATA" Create="yes" Resource="${RESOURCE}"/>
    </Configuration>

    <Import File="${SOURCESPATH}isc" Recurse="1"/>
    
    <Log Level="1" Text="Configuring Production"/>
    <Invoke Class="isc.py.util.Installer" Method="ConfigureProduction" CheckStatus="true"/>
    
    <Log Level="1" Text="Enabling OS level Authentication"/>
    <Invoke Class="isc.py.util.Installer" Method="OSAuth" CheckStatus="true"/>
    
    <Log Level="1" Text="Loading %ZSTART, %ZLANGC00 routines"/>
    <Invoke Class="isc.py.util.Installer" Method="LoadZRoutines" CheckStatus="true">
    <Arg Value="${SOURCESPATH}rtn"/>
    </Invoke>
  </Namespace>
</Manifest>
}

ClassMethod Setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
  Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "Install")
}

/// Set production as default. 
/// Load test data
/// Set libpython3.6m.so as PythonLib
ClassMethod ConfigureProduction() As %Status
{
	set production = "isc.py.test.Production"
	set ^Ens.Configuration("csp","LastProduction") = production
	set sc = ##class(isc.py.test.CannibalizationData).Import()
	quit:$$$ISERR(sc) sc
	
	set setting = ##class(Ens.Config.Setting).%New()
	set setting.Name = "PythonLib"
	set setting.Value = "libpython3.6m.so"

	set exists = ##class(Ens.Config.Item).NameExists(production, "isc.py.ens.Operation", .itemId)
	set item =  ##class(Ens.Config.Item).%OpenId(itemId)
	do item.Settings.Insert(setting)
	set sc = item.%Save()
	quit:$$$ISERR(sc) sc
	
	// Try to adjust default process
	set process = "isc.py.test.Process"
	set sc = ##class(%Compiler.UDL.TextServices).GetTextAsString(,process, .code)
	quit:$$$ISERR(sc) sc
	
	set user = "Admin"
	set password = "SYS"
	set installDir = $system.Util.GetEnviron("ISC_PACKAGE_INSTALLDIR")
	
	
	set code = $replace(code, "[""dev"", ""123""]", "["""_user_""", """_password_"""]") // JDBC password
	set code = $replace(code, "/InterSystems/IRIS", installDir) // JDBC Jar path
	set code = $replace(code, "DSN=ENSEMBLE(PYTHON);UID=dev;PWD=123", $$$FormatText("Driver=%1/bin/libirisodbcu35.so;Server=localhost;Port=51773;database=%2;UID=%3;PWD=%4;Authentication Method=0",installDir, $namespace, user, password))
	set code = $replace(code, "C:\InterSystems\Ensemble\mgr\Temp\", ##class(%File).NormalizeDirectory(##class(%SYS.System).TempDirectory()))
	
	set sc = ##class(%Compiler.UDL.TextServices).SetTextFromString(,process, .code)
	quit:$$$ISERR(sc) sc
	
	set sc = $system.OBJ.Compile(process, "ck")
		
	quit sc
}

/// Enable OS Authentication
ClassMethod OSAuth() As %Status
{
	new $namespace
	set $namespace = "%SYS"
	set sc = ##Class(Security.System).Get($$$SystemSecurityName,.properties)
	quit:$$$ISERR(sc) sc
	
	set autheEnabled = properties("AutheEnabled")
	quit:'$data(autheEnabled) $$$ERROR($$$PropertyDoesNotExist, "AutheEnabled")
	set properties("AutheEnabled") = $ZBOOLEAN(+autheEnabled, $$$AutheOS, 7)
	set sc = ##Class(Security.System).Modify($$$SystemSecurityName, .properties) 
	
	quit sc
}

ClassMethod LoadZRoutines(dir As %String) As %Status
{
	new $namespace
	set $namespace = "%SYS"
	
	set dir = ##class(%File).NormalizeDirectory(dir)
	set sc = $system.OBJ.ImportDir(dir, "*.xml", "c")
	quit sc
}

}

