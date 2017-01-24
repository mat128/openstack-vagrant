require 'spec_helper'
require 'vagrant-openstack-cloud-provider/action/read_ssh_info_from_api'

RSpec.describe VagrantPlugins::OpenStack::Action::ReadSSHInfoFromAPI do
  describe '#call' do
    it "passes proper parameters to read_ssh_info and puts them in machine_ssh_info" do
      app = lambda { |only_one_parameter| }
      env = {:openstack_compute => :my_compute, :machine => :my_machine}

      subject = described_class.new(app, nil)
      expect(subject).to receive(:read_ssh_info).with(:my_compute, :my_machine).and_return(:my_ssh_info)

      subject.call(env)
      expect(env[:machine_ssh_info]).to eq(:my_ssh_info)
    end

    it "calls app.call with the right env" do
      app = double()
      env = {:openstack_compute => nil, :machine => nil}
      expect(app).to receive(:call).with(env)

      subject = described_class.new(app, nil)
      expect(subject).to receive(:read_ssh_info)
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
    let(:invalid_openstack_server_instance) { double }
    let(:openstack_server_instance) { double }
    let(:provider_config) { double(:config,
                                   :public_network_name => "public",
                                   :ssh_username => "username")
    }

    it "should return nil if machine is nil" do
      expect(machine).to receive(:id).and_return(nil)
      expect(subject.read_ssh_info(nil, machine)).to eq(nil)
    end

    it "assigns machine_id to nil and returns nil if openstack returns nil" do
      expect(machine).to receive(:id).at_least(:once).and_return("anything")
      expect(machine).to receive(:id=).at_least(:once)

      expect(servers).to receive(:get).and_return(nil)
      expect(openstack).to receive(:servers).and_return(servers)

      expect(subject.read_ssh_info(openstack, machine)).to eq(nil)
    end

    it "returns nil when something bad happens while fetching address" do
      expect(machine).to receive(:id).at_least(:once).and_return("anything")
      expect(machine).to receive(:provider_config).and_return(provider_config)

      expect(invalid_openstack_server_instance).to receive(:addresses).and_raise(StandardError)
      expect(servers).to receive(:get).and_return(invalid_openstack_server_instance)
      expect(openstack).to receive(:servers).and_return(servers)

      result = subject.read_ssh_info(openstack, machine)

      expect(result).to eq({:port => 22, :username => 'username', :host => nil})
    end

    it "returns a proper ssh_info hash" do
      expect(provider_config).to receive(:ssh_username).and_return("root")
      expect(machine).to receive(:id).at_least(:once).and_return("anything")
      expect(machine).to receive(:provider_config).and_return(provider_config)

      valid_server_addresses = {
        "public" => [
          { "addr" => 'server1.example.org' },
          { "addr" => 'server2.example.org' }
        ]
      }

      expect(openstack_server_instance).to receive(:addresses).and_return(valid_server_addresses)

      expect(servers).to receive(:get).and_return(openstack_server_instance)
      expect(openstack).to receive(:servers).and_return(servers)

      result = subject.read_ssh_info(openstack, machine)

      expect(result).to eq({:port => 22, :username => "root", :host => "server2.example.org"})
    end

    it "uses the public network name from the config" do
      expect(provider_config).to receive(:public_network_name).and_return("my_custom_public_network_name")
      expect(machine).to receive(:id).at_least(:once).and_return("anything")

      expect(machine).to receive(:provider_config).and_return(provider_config)

      valid_server_addresses = {
        "my_custom_public_network_name" => [
          { "addr" => 'server1.example.org' },
          { "addr" => 'server2.example.org' }
        ]
      }

      expect(openstack_server_instance).to receive(:addresses).and_return(valid_server_addresses)

      expect(servers).to receive(:get).and_return(openstack_server_instance)
      expect(openstack).to receive(:servers).and_return(servers)

      result = subject.read_ssh_info(openstack, machine)

      expect(result).to eq({:port => 22, :username => "username", :host => "server2.example.org"})
    end
  end
end
