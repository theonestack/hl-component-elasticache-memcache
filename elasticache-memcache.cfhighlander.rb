CfhighlanderTemplate do

  DependsOn 'lib-ec2@0.1.0'

  Description "#{component_name} - #{component_version} - (#{template_name}@#{template_version})"
  Name 'memcached'

  Parameters do
    ComponentParam 'VPCId'

    ComponentParam 'EnvironmentName', 'dev', isGlobal: true

    ComponentParam 'EnvironmentType', 'development', 
      allowedValues: ['development','production'], isGlobal: true

    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'

    ComponentParam 'SubnetIds', type: 'CommaDelimitedList',
      description: 'Comma-delimited list of subnets to launch memcache in'

    ComponentParam 'DnsDomain'

    ComponentParam 'InstanceType', 'cache.t3.small',
      description: 'The compute and memory capacity of the nodes in the cluster'

    ComponentParam 'NumOfNodes', 1

  end
end
