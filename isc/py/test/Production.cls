/// Sample production
Class isc.py.test.Production Extends Ens.Production
{

/// Register callout lib system-wide
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
	set sc = ##class(isc.py.Callout).Setup()
	quit sc
}

XData ProductionDefinition
{
<Production Name="isc.py.test.Production" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Item Name="isc.py.ens.Operation" Category="" ClassName="isc.py.ens.Operation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
  </Item>
  <Item Name="isc.py.test.Process" Category="" ClassName="isc.py.test.Process" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
  </Item>
</Production>
}

}

