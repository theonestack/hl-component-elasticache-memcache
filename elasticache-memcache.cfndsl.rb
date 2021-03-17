CloudFormation do

  Condition("IsMoreThanOneNode", FnNot(FnEquals("NumOfNodes", "1")))

  component_name = external_parameters.fetch(:component_name)

  tags = []
  tags << { Key: 'Environment', Value: Ref(:EnvironmentName) }
  tags << { Key: 'EnvironmentType', Value: Ref(:EnvironmentType) }

  extra_tags = external_parameters.fetch(:extra_tags, [])
  extra_tags.each { |key,value| tags << { Key: key, Value: value } }

  ip_blocks = external_parameters.fetch(:ip_blocks, {})
  security_group_rules = external_parameters.fetch(:security_group_rules, [])

  EC2_SecurityGroup(:MemcachedSecurityGroup) {
    VpcId Ref(:VPCId)
    GroupDescription FnSub("${EnvironmentName}-#{component_name}")
    
    if security_group_rules.any?
      SecurityGroupIngress generate_security_group_rules(security_group_rules,ip_blocks)
    end

    SecurityGroupEgress([
      {
        CidrIp: '0.0.0.0/0',
        Description: 'Outbound for all ports',
        IpProtocol: '-1',
      }
    ])
    Tags tags + [{ Key: 'Name', Value: FnSub("${EnvironmentName}-#{component_name}") }]
  }
  Output(:SecurityGroupId) {
    Value Ref(:MemcachedSecurityGroup)
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-SecurityGroup")
  }

  ElastiCache_SubnetGroup(:MemcachedSubnetGroup) {
    Description FnSub("${EnvironmentName} - #{component_name} subnet group")
    SubnetIds Ref(:SubnetIds)
  }

  family = external_parameters.fetch(:family, 'memcached1.6')
  parameters = external_parameters.fetch(:parameters, {})
  unless parameters.empty?
    parameters = parameters.transform_keys {|k| k.split('_').collect(&:capitalize).join }
  end
  ElastiCache_ParameterGroup(:MemcachedParameterGroup) {
    CacheParameterGroupFamily family
    Description FnSub("${EnvironmentName} - #{component_name} parameter group")
    Properties parameters unless parameters.empty?
  }

  cluster_name = external_parameters.fetch(:cluster_name, '${EnvironmentName}')
  engine_version = external_parameters.fetch(:engine_version, nil)
  memcached_port = external_parameters.fetch(:memcached_port, nil)
  minor_upgrade = external_parameters.fetch(:minor_upgrade, nil)
  ElastiCache_CacheCluster(:MemcachedCluster) {
    ClusterName FnSub(cluster_name)
    Engine 'memcached'
    EngineVersion engine_version unless engine_version.nil?
    Port memcache_port unless memcached_port.nil?
    AutoMinorVersionUpgrade unless minor_upgrade.nil?
    CacheNodeType Ref(:InstanceType)
    AZMode FnIf('IsMoreThanOneNode', 'cross-az', 'single-az')
    NumCacheNodes Ref(:NumOfNodes)
    CacheParameterGroupName Ref(:MemcachedParameterGroup)
    VpcSecurityGroupIds [ Ref(:MemcachedSecurityGroup) ]
    CacheSubnetGroupName Ref(:MemcachedSubnetGroup)
    Tags tags
  }
  Output(:EndpointAddress) {
    Value FnGetAtt(:MemcachedCluster,'ConfigurationEndpoint.Address')
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-EndpointAddress")
  }

  dns_record = external_parameters.fetch(:dns_record, 'memcache')
  Route53_RecordSet(:MemcachedClusterDns) {
    HostedZoneName FnJoin('', [ Ref(:EnvironmentName), '.', Ref(:DnsDomain), '.'])
    Name FnJoin('', [dns_record, '.', Ref(:EnvironmentName), '.', Ref(:DnsDomain), '.'])
    Type 'CNAME'
    TTL '60'
    ResourceRecords [ FnGetAtt(:MemcachedCluster,'ConfigurationEndpoint.Address') ]
  }

end
