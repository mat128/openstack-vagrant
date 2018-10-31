require "fog/openstack"
require "log4r"
require 'promise'

module VagrantPlugins
  module OpenStack
    module Action
      # This action connects to OpenStack, verifies credentials work, and
      # puts the OpenStack connection object into the `:openstack_compute` key
      # in the environment.
      class ConnectOpenStack
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::connect_openstack")
        end

        def call(env)
          config = env[:machine].provider_config

          openstack_options = {
              :provider => :openstack,
              :openstack_region => config.region,
              :openstack_username => config.username,
              :openstack_api_key => config.api_key,
              :openstack_auth_url => config.endpoint,
              :openstack_tenant => config.tenant
          }

          $openstack_compute ||= get_fog_promise('Compute', openstack_options)
          $openstack_network ||= get_fog_promise('Network', openstack_options)

          env[:openstack_compute] = $openstack_compute
          env[:openstack_network] = $openstack_network

          @app.call(env)
        end

        private

        def get_fog_promise(service_name, openstack_options)
          Kernel.promise {
            @logger.info("Initializing OpenStack #{service_name}...")
            Fog.const_get(service_name).new(openstack_options)
          }
        end
      end
    end
  end
end
