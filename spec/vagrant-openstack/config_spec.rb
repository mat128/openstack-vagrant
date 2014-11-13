require 'spec_helper'
require "vagrant-openstack/config"

describe VagrantPlugins::OpenStack::Config do
  describe "defaults" do
    let(:vagrant_public_key) { Vagrant.source_root.join("keys/vagrant.pub") }

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    its(:api_key)  { should be_nil }
    its(:endpoint) { should be_nil }
    its(:region) { should be_nil }
    its(:flavor)   { should eq(/m1.tiny/) }
    its(:image)    { should eq(/cirros/) }
    its(:server_name) { should be_nil }
    its(:username) { should be_nil }
    its(:keypair_name) { should be_nil }
    its(:ssh_username) { should be_nil }
    its(:user_data) { should eq("") }
    its(:metadata) { should eq({}) }
    its(:public_network_name) { should eq("public") }
    its(:networks) { should eq(["public"]) }
    its(:tenant) { should be_nil }
  end

  describe "overriding defaults" do
    [:api_key,
      :endpoint,
      :region,
      :flavor,
      :image,
      :server_name,
      :username,
      :keypair_name,
      :ssh_username,
      :metadata,
      :public_network_name,
      :networks,
      :tenant].each do |attribute|
      it "should not default #{attribute} if overridden" do
        subject.send("#{attribute}=", "foo")
        subject.finalize!
        subject.send(attribute).should == "foo"
      end
    end
  end

  describe "validation" do
    let(:machine) { double("machine") }

    subject do
      super().tap do |o|
        o.finalize!
      end
    end

    context "with good values" do
      it "should validate"
    end

    context "the API key" do
      it "should error if not given"
    end

    context "the public key path" do
      it "should have errors if the key doesn't exist"
      it "should not have errors if the key exists with an absolute path"
      it "should not have errors if the key exists with a relative path"
    end

    context "the username" do
      it "should error if not given"
    end
  end
end
