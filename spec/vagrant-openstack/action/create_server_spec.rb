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
end