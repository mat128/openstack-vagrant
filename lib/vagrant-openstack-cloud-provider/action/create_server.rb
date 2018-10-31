require "fog/openstack"
require "log4r"
require "json"

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
          config = env[:machine].provider_config

          # Find the flavor
          env[:ui].info(I18n.t("vagrant_openstack.finding_flavor"))
          flavor = find_matching(env[:openstack_compute].flavors.all, config.flavor)
          raise Errors::NoMatchingFlavor if !flavor

          # Find the image
          env[:ui].info(I18n.t("vagrant_openstack.finding_image"))
          image = find_matching(env[:openstack_compute].images, config.image)
          raise Errors::NoMatchingImage if !image

          # Find the networks
          effective_networks = []
          if !config.networks.nil? and config.networks.any?
            env[:ui].info(I18n.t("vagrant_openstack.finding_network"))
            available_networks = env[:openstack_network].list_networks[:body]["networks"]

            for network_name in config.networks
              match = find_matching(available_networks, network_name)
              unless match
                raise Errors::NoMatchingNetwork,
                      :network_name => network_name
              end
              effective_networks << match
            end
          end

          # Figure out the name for the server
          server_name = config.server_name || env[:machine].name

          # Output the settings we're going to use to the user
          env[:ui].info(I18n.t("vagrant_openstack.launching_server"))
          env[:ui].info(" -- Flavor: #{flavor.name}")
          env[:ui].info(" -- Image: #{image.name}")
          if effective_networks.any?
            env[:ui].info(' -- Network(s): ')
            for net in effective_networks
              env[:ui].info("      - #{net['name']}")
            end
          end
          env[:ui].info(" -- Name: #{server_name}")

          openstack_nics = []

          for net in effective_networks
            openstack_nics << {'net_id' => net['id']}
          end

          # Build the options for launching...
          options = {
            :flavor_ref         => flavor.id,
            :image_ref          => image.id,
            :name               => server_name,
            :key_name           => config.keypair_name,
            :user_data_encoded  => Base64.encode64(config.user_data),
            :metadata           => config.metadata,
            :os_scheduler_hints => config.scheduler_hints
          }

          if openstack_nics.any?
            options[:nics] = openstack_nics
          end

          # Create the server
          launch_start_time = Time.now
          server = env[:openstack_compute].servers.create(options)

          # Store the ID right away so we can track it
          env[:machine].id = server.id

          # Wait for the server to finish building
          env[:ui].info("Instance UUID: #{env[:machine].id}")
          env[:ui].info(I18n.t("vagrant_openstack.waiting_for_build"))
          retryable(:on => Timeout::Error, :tries => 200) do
            # If we're interrupted don't worry about waiting
            next if env[:interrupted]

            # Wait for the server to be ready
            begin
              (1..config.instance_build_timeout / config.instance_build_status_check_interval).each do |n|
                if config.report_progress
                  env[:ui].clear_line
                  env[:ui].report_progress(n * config.instance_build_status_check_interval, false)
                end

                server = env[:openstack_compute].servers.get(env[:machine].id)
                break if self.server_to_be_available?(server)
                sleep config.instance_build_status_check_interval
              end
              server = env[:openstack_compute].servers.get(env[:machine].id)
              raise unless self.server_to_be_available?(server)
            rescue
              raise Errors::CreateBadState, :state => server.state
            end
          end

          env[:ui].info(I18n.t("vagrant_openstack.active",
                        :elapsed => (Time.now - launch_start_time).floor))
          env[:machine].data_dir.join("cached_metadata").open("w+") do |f|
            f.write(server.to_json)
          end
          public_ip_address = server.addresses[config.public_network_name].last['addr'] rescue nil
          env[:ui].info("Instance IP address: #{public_ip_address}")

          unless env[:interrupted]
            # Clear the line one more time so the progress is removed
            env[:ui].clear_line
            ssh_is_responding?(env,
                               timeout=config.instance_ssh_timeout,
                               sleep_interval=config.instance_ssh_check_interval)
            env[:ui].info(I18n.t("vagrant_openstack.ready",
                          :elapsed => (Time.now - launch_start_time).floor))
          end

          @app.call(env)
        end

        protected

        def ssh_is_responding?(env, timeout, sleep_interval)
           begin
             # Wait for SSH to become available
             env[:ui].info(I18n.t("vagrant_openstack.waiting_for_ssh"))
             (1..timeout / sleep_interval).each do |n|
               begin
                 # If we're interrupted then just back out
                 break if env[:interrupted]
                 break if env[:machine].communicate.ready?
               rescue Errno::ENETUNREACH
               end
               sleep sleep_interval
             end
             unless env[:machine].communicate.ready?
                raise Errors::SshWaitTimeout.new(
                    :seconds => sleep_interval * (timeout / sleep_interval))
             end
           rescue Exception => msg
             raise Errors::SshUnavailable.new(:error => msg)
           end
        end

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
