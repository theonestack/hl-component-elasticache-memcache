CfhighlanderTemplate do
  Name 'ElastiCacheMemcache'
  Description "#{component_name} - #{component_version}"
  ComponentVersion component_version

  DependsOn 'vpc'

  Parameters do
    ComponentParam 'VPCId'
    ComponentParam 'StackOctet', isGlobal: true
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true, allowedValues: ['development', 'production']
    ComponentParam 'DnsDomain'
    ComponentParam 'CacheInstanceType'
    ComponentParam 'CacheNodes', 1

    maximum_availability_zones.times do |az|
      ComponentParam "SubnetCache#{az}"
    end
  end
end
