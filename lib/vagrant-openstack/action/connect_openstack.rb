require "fog"
require "log4r"

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
          # Get the configs
          config   = env[:machine].provider_config
          openstack_connection_informations = {
              :provider => :openstack,
              :openstack_username => config.username,
              :openstack_api_key => config.api_key,
              :openstack_auth_url => config.endpoint
          }

          @logger.info("Connecting to OpenStack Compute...")
          env[:openstack_compute] = Fog::Compute.new(openstack_connection_informations)

          @logger.info("Connecting to OpenStack Network...")
          env[:openstack_network] = Fog::Network.new(openstack_connection_informations)

          @app.call(env)
        end
      end
    end
  end
end
