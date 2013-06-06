require 'spec_helper'
require 'vagrant-openstack/action/create_server'

describe VagrantPlugins::OpenStack::Action::CreateServer do
  describe '#server_to_be_available?' do
    subject {
      described_class.new(nil, nil)
    }

    let(:server) { double }

    it "returns true when server is active" do
      server.stub(:state).and_return('ACTIVE')
      subject.server_to_be_available?(server).should == true
    end

    it "should raise when the server state is ERROR" do
      server.stub(:state).and_return('ERROR')
      expect { subject.server_to_be_available?(server) }.to raise_error(RuntimeError)
    end
  end

  describe '#find_matching' do
    subject {
      described_class.new(nil, nil)
    }

    it "returns a match for a list of hashes" do
      haystack = [{"status"=>"ACTIVE", "subnets"=>["d8908f8c-07f4-405b-bbab-e19c768f293f"], "name"=>"solidfire", "provider:physical_network"=>"physnet1", "admin_state_up"=>true, "tenant_id"=>"2c9fba23721f4126ab244020e641f5f5", "provider:network_type"=>"vlan", "router:external"=>false, "shared"=>true, "id"=>"192702e6-3444-4162-b244-3af8b50fbb45", "provider:segmentation_id"=>3999}, {"status"=>"ACTIVE", "subnets"=>["d4318e28-5acd-415f-b300-0502f33b0dea"], "name"=>"public", "provider:physical_network"=>"physnet0", "admin_state_up"=>true, "tenant_id"=>"2c9fba23721f4126ab244020e641f5f5", "provider:network_type"=>"vlan", "router:external"=>false, "shared"=>true, "id"=>"e44bf8cb-7326-4abc-b96d-5404d5ed7767", "provider:segmentation_id"=>2753}]
      needle = {"status"=>"ACTIVE", "subnets"=>["d4318e28-5acd-415f-b300-0502f33b0dea"], "name"=>"public", "provider:physical_network"=>"physnet0", "admin_state_up"=>true, "tenant_id"=>"2c9fba23721f4126ab244020e641f5f5", "provider:network_type"=>"vlan", "router:external"=>false, "shared"=>true, "id"=>"e44bf8cb-7326-4abc-b96d-5404d5ed7767", "provider:segmentation_id"=>2753}

      subject.send('find_matching', haystack, needle['name']).should == needle
    end

    it "returns a match for a list of objects with matching id" do
      object1 = double()
      object1.stub('id' => 'matching_value')
      object1.stub('name' => 'not_this')

      haystack = [object1]
      subject.send('find_matching', haystack, 'matching_value').should == object1
    end

    it "returns a match for a list of objects with matching name" do
      object1 = double()
      object1.stub('id' => 'not_this')
      object1.stub('name' => 'matching_value')

      haystack = [object1]
      subject.send('find_matching', haystack, 'matching_value').should == object1
    end

    it "returns a match for a list of objects with a matching regexp" do
      object1 = double()
      object1.stub('id' => 'not_this')
      object1.stub('name' => '2020 des fin fin')

      haystack = [object1]
      subject.send('find_matching', haystack, /des fin/).should == object1
    end
  end
end
