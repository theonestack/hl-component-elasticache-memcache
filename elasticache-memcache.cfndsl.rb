CloudFormation do

  Condition("IsMoreThanOneNode", FnNot(FnEquals("CacheNodes", "1")))
  az_conditions_resources('SubnetCache', maximum_availability_zones)

  tags = []
  tags << { Key: 'Environment', Value: Ref(:EnvironmentName) }
  tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType) }

  extra_tags.each { |key,value| tags << { Key: key, Value: value } } if defined? extra_tags

  EC2_SecurityGroup(:CacheSecurityGroup) do
    VpcId Ref('VPCId')
    GroupDescription FnJoin(' ', [ Ref(:EnvironmentName), component_name, 'security group' ])
    SecurityGroupIngress sg_create_rules(security_groups, ip_blocks)
    Tags tags + [{ Key: 'Name', Value: FnJoin('-', [ Ref(:EnvironmentName), component_name, 'security-group' ])}]
  end

  ElastiCache_SubnetGroup(:CacheSubnetGroup) {
    Description FnJoin('',[ Ref(:EnvironmentName), component_name, 'subnet group'] )
    SubnetIds az_conditional_resources('SubnetCache', maximum_availability_zones)
  }

  ElastiCache_ParameterGroup(:CacheParameterGroup) {
    CacheParameterGroupFamily family
    Description FnJoin(' ',[ Ref(:EnvironmentName), component_name, 'parameter group'] )
    Properties parameters if defined? parameters
  }

  ElastiCache_CacheCluster(:ElasticacheCluster) {
    Engine 'memcached'
    EngineVersion engine_version if defined? engine_version
    Port memcache_port if defined? memcache_port
    AutoMinorVersionUpgrade minor_upgrade if defined? minor_upgrade
    CacheNodeType Ref(:CacheInstanceType)
    AZMode FnIf('IsMoreThanOneNode', 'cross-az', 'single-az')
    NumCacheNodes Ref(:CacheNodes)
    CacheParameterGroupName Ref(:CacheParameterGroup)
    VpcSecurityGroupIds [ Ref(:CacheSecurityGroup) ]
    CacheSubnetGroupName Ref(:CacheSubnetGroup)
  }

  record = defined?(dns_record) ? "#{dns_record}" : 'memcache'

  Route53_RecordSet(:ElasticacheRecord) {
    HostedZoneName FnJoin('', [ Ref(:EnvironmentName), '.', Ref(:DnsDomain), '.'])
    Name FnJoin('', [record, '.', Ref(:EnvironmentName), '.', Ref(:DnsDomain), '.'])
    Type 'CNAME'
    TTL '60'
    ResourceRecords [ FnGetAtt(:ElasticacheCluster,'ConfigurationEndpoint.Address') ]
  }

end
