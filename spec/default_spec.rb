require 'yaml'

describe 'compiled component' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/default.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/default/memcached.compiled.yaml") }

  context 'Resource Memcached Security Group' do
    let(:properties) { template["Resources"]["MemcachedSecurityGroup"]["Properties"] }

    it 'has property GroupDescription ' do
      expect(properties["GroupDescription"]).to eq({"Fn::Sub"=>"${EnvironmentName}-memcached"})
    end

    it 'has property VpcId ' do
      expect(properties["VpcId"]).to eq({"Ref"=>"VPCId"})
    end

    it 'has property Tags' do
      expect(properties["Tags"]).to eq([
        {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, 
        {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}},
        {"Key"=>"Name", "Value"=>{"Fn::Sub"=>"${EnvironmentName}-memcached"}}
      ])
    end

  end

  context 'Resource Memcached Subnet Group' do
    let(:properties) { template["Resources"]["MemcachedSubnetGroup"]["Properties"] }

    it 'has property Description ' do
      expect(properties["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} - memcached subnet group"})
    end

    it 'has property SubnetIds ' do
      expect(properties["SubnetIds"]).to eq({"Ref"=>"SubnetIds"})
    end

  end

  context 'Resource Parameter Group' do
    let(:properties) { template["Resources"]["MemcachedParameterGroup"]["Properties"] }

    it 'has property Description ' do
      expect(properties["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} - memcached parameter group"})
    end

    it 'has property CacheParameterGroupFamily ' do
      expect(properties["CacheParameterGroupFamily"]).to eq('memcached1.6')
    end

  end

  context 'Resource Memcached Cluster' do
    let(:properties) { template["Resources"]["MemcachedCluster"]["Properties"] }

    it 'has property ClusterName ' do
      expect(properties["ClusterName"]).to eq({"Fn::Sub"=>"${EnvironmentName}"})
    end

    it 'has property Engine' do
      expect(properties["Engine"]).to eq('memcached')
    end

    it 'has property Tags' do
      expect(properties["Tags"]).to eq([
        {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, 
        {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
    end

  end
end