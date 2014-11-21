require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module OpenStack
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action is called to destroy the remote machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use CheckCreated
          b.use ConnectOpenStack
          b.use DeleteServer
        end
      end

      # This action is called to read the SSH info of the machine. The
      # resulting state is expected to be put into the `:machine_ssh_info`
      # key.
      def self.action_read_ssh_info
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenStack
          b.use ReadSSHInfo
        end
      end

      # This action is called to read the state of the machine. The
      # resulting state is expected to be put into the `:machine_state_id`
      # key.
      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ConnectOpenStack
          b.use ReadState
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use CheckCreated
          b.use SSHExec
        end
      end

      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use CheckCreated
          b.use SSHRun
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use defined?(HandleBox) ? HandleBox : HandleBoxUrl
          b.use ConfigValidate
          b.use Call, Created do |env, b2|
            unless env[:result]
              b2.use ConnectOpenStack
              b2.use Provision
              b2.use SyncFolders
              b2.use SetHostname
              b2.use WarnNetworks
              b2.use CreateServer
            end
          end
        end
      end

      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use CheckCreated
          b.use Provision
          b.use SyncFolders
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :ConnectOpenStack, action_root.join("connect_openstack")
      autoload :CreateServer, action_root.join("create_server")
      autoload :DeleteServer, action_root.join("delete_server")
      autoload :Created, action_root.join("created")
      autoload :CheckCreated, action_root.join("check_created")
      autoload :ReadSSHInfo, action_root.join("read_ssh_info")
      autoload :ReadState, action_root.join("read_state")
      autoload :SyncFolders, action_root.join("sync_folders")
      autoload :WarnNetworks, action_root.join("warn_networks")
    end
  end
end
