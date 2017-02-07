require "vagrant"

module VagrantPlugins
  module OpenStack
    module Errors
      class VagrantOpenStackError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_openstack.errors")
      end

      class CreateBadState < VagrantOpenStackError
        error_key(:create_bad_state)
      end

      class SshWaitTimeout < VagrantOpenStackError
        error_key(:ssh_wait_timeout)
      end

      class SshUnavailable < VagrantOpenStackError
        error_key(:ssh_unavailable)
      end

      class NoMatchingFlavor < VagrantOpenStackError
        error_key(:no_matching_flavor)
      end

      class NoMatchingImage < VagrantOpenStackError
        error_key(:no_matching_image)
      end

      class NoMatchingNetwork < VagrantOpenStackError
        error_key(:no_matching_network)
      end

      class RsyncError < VagrantOpenStackError
        error_key(:rsync_error)
      end
    end
  end
end
