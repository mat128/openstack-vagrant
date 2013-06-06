require "fog"
require "log4r"

require 'vagrant/util/retryable'

module VagrantPlugins
  module OpenStack
    module Action
      # This creates the OpenStack server.
      class CreateServer
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::create_server")
        end

        def server_to_be_available?(server)
          raise if server.state == 'ERROR'
          server.state == 'ACTIVE'
        end

        def call(env)
          # Get the configs
          config   = env[:machine].provider_config

          # Find the flavor
          env[:ui].info(I18n.t("vagrant_openstack.finding_flavor"))
          flavor = find_matching(env[:openstack_compute].flavors.all, config.flavor)
          raise Errors::NoMatchingFlavor if !flavor

          # Find the image
          env[:ui].info(I18n.t("vagrant_openstack.finding_image"))
          image = find_matching(env[:openstack_compute].images, config.image)
          raise Errors::NoMatchingImage if !image

          # Find the networks
          env[:ui].info(I18n.t("vagrant_openstack.finding_network"))
          network = find_matching(env[:openstack_network].list_networks[:body]["networks"], config.public_network_name)
          raise Errors::NoMatchingNetwork if !network

          # Figure out the name for the server
          server_name = config.server_name || env[:machine].name

          # Output the settings we're going to use to the user
          env[:ui].info(I18n.t("vagrant_openstack.launching_server"))
          env[:ui].info(" -- Flavor: #{flavor.name}")
          env[:ui].info(" -- Image: #{image.name}")
          env[:ui].info(" -- Network: #{network['name']}")
          env[:ui].info(" -- Name: #{server_name}")

          # Build the options for launching...
          options = {
            :flavor_ref  => flavor.id,
            :image_ref   => image.id,
            :name        => server_name,
            :key_name    => config.keypair_name,
            :user_data_encoded => Base64.encode64(config.user_data),
            :nics        => [{"net_id" => network['id']}],
          }

          # Create the server
          server = env[:openstack_compute].servers.create(options)

          # Store the ID right away so we can track it
          env[:machine].id = server.id

          # Wait for the server to finish building
          env[:ui].info(I18n.t("vagrant_openstack.waiting_for_build"))
          retryable(:on => Timeout::Error, :tries => 200) do
            # If we're interrupted don't worry about waiting
            next if env[:interrupted]

            # Wait for the server to be ready
            begin
              (1..60).each do |n|
                env[:ui].clear_line
                env[:ui].report_progress(n, 60, true)
                server = env[:openstack_compute].servers.get(env[:machine].id)
                break if self.server_to_be_available?(server)
                sleep 1
              end
            rescue
              raise Errors::CreateBadState, :state => server.state
            end
          end

          unless env[:interrupted]
            # Clear the line one more time so the progress is removed
            env[:ui].clear_line

            # Wait for SSH to become available
            env[:ui].info(I18n.t("vagrant_openstack.waiting_for_ssh"))
            while true
              begin
                # If we're interrupted then just back out
                break if env[:interrupted]
                break if env[:machine].communicate.ready?
              rescue Errno::ENETUNREACH
              end
              sleep 2
            end

            env[:ui].info(I18n.t("vagrant_openstack.ready"))
          end

          @app.call(env)
        end

        protected

        # This method finds a matching _thing_ in a collection of
        # _things_. This works matching if the ID or NAME equals to
        # `name`. Or, if `name` is a regexp, a partial match is chosen
        # as well.
        def find_matching(collection, name)
          collection.each do |single|
            if single.is_a?(Hash)
              return single if single['name'] == name
            else
              return single if single.id == name
              return single if single.name == name
              return single if name.is_a?(Regexp) && name =~ single.name
            end
          end

          nil
        end
      end
    end
  end
end
