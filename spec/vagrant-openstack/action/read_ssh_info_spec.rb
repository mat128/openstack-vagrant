require 'spec_helper'
require 'vagrant-openstack/action/read_ssh_info_from_api'

describe VagrantPlugins::OpenStack::Action::ReadSSHInfoFromAPI do
  describe '#call' do
    it "passes proper parameters to read_ssh_info and puts them in machine_ssh_info" do
      app = lambda { |only_one_parameter| }
      env = {:openstack_compute => :my_compute, :machine => :my_machine}

      subject = described_class.new(app, nil)
      subject.should_receive(:read_ssh_info).with(:my_compute, :my_machine).and_return(:my_ssh_info)

      subject.call(env)
      env[:machine_ssh_info].should == :my_ssh_info
    end

    it "calls app.call with the right env" do
      app = double()
      env = {:openstack_compute => nil, :machine => nil}
      app.should_receive(:call).with(env)

      subject = described_class.new(app, nil)
      subject.stub(:read_ssh_info)
      subject.call(env)
    end
  end

  describe '#read_ssh_info' do
    subject {
      described_class.new(nil, nil)
    }

    let(:machine) { double }
    let(:openstack) { double }
    let(:servers) { double }
    let(:provider_config) do
      mock = double
      mock.stub(:public_network_name => "public")
      mock.stub(:ssh_username => "username")
      mock
    end

    it "should return nil if machine is nil" do
      machine.stub(:id).and_return(nil)
      subject.read_ssh_info(nil, machine).should == nil
    end

    it "assigns machine_id to nil and returns nil if openstack returns nil" do
      machine.stub(:id => "anything")
      machine.stub(:id=)

      servers.should_receive(:get).and_return(nil)
      openstack.should_receive(:servers).and_return(servers)

      subject.read_ssh_info(openstack, machine).should == nil
    end

    it "returns nil when something bad happens while fetching address" do
      provider_config.stub(:ssh_username)
      machine.stub(:id => "anything")
      machine.stub(:provider_config => provider_config)

      invalid_openstack_server_instance = double()
      invalid_openstack_server_instance.should_receive(:addresses).and_raise(StandardError)
      servers.should_receive(:get).and_return(invalid_openstack_server_instance)
      openstack.should_receive(:servers).and_return(servers)

      result = subject.read_ssh_info(openstack, machine)

      result[:port].should == 22
      result[:host].should == nil
    end

    it "returns a proper ssh_info hash" do
      provider_config.stub(:ssh_username => "root")
      machine.stub(:id => "anything")
      machine.stub(:provider_config => provider_config)

      valid_server_addresses = {
        "public" => [
          { "addr" => 'server1.example.org' },
          { "addr" => 'server2.example.org' }
        ]
      }

      openstack_server_instance = double()
      openstack_server_instance.should_receive(:addresses).and_return(valid_server_addresses)

      servers.should_receive(:get).and_return(openstack_server_instance)
      openstack.should_receive(:servers).and_return(servers)

      result = subject.read_ssh_info(openstack, machine)

      result[:port].should == 22
      result[:host].should == "server2.example.org"
      result[:username].should == "root"
    end

    it "uses the public network name from the config" do
      provider_config.stub(:public_network_name => "my_custom_public_network_name")
      machine.stub(:id => "anything")
      machine.stub(:provider_config => provider_config)

      valid_server_addresses = {
        "my_custom_public_network_name" => [
          { "addr" => 'server1.example.org' },
          { "addr" => 'server2.example.org' }
        ]
      }

      openstack_server_instance = double()
      openstack_server_instance.should_receive(:addresses).and_return(valid_server_addresses)

      servers.should_receive(:get).and_return(openstack_server_instance)
      openstack.should_receive(:servers).and_return(servers)

      result = subject.read_ssh_info(openstack, machine)

      result[:host].should == "server2.example.org"
    end
  end
end