require "log4r"
require "json"

class ::Hash
  def method_missing(name)
    return self[name] if key? name
    self.each { |k,v| return v if k.to_s.to_sym == name }
    super.method_missing name
  end
end

module VagrantPlugins
  module OpenStack
    module Action
      # This action reads the SSH info for the machine and puts it into the
      # `:machine_ssh_info` key in the environment.
      class ReadSSHInfoFromCache
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_openstack::action::read_ssh_info")
        end

        def call(env)
          ssh_info = read_ssh_info(env[:machine])
          
          if ssh_info[:host] != nil
            env[:machine_ssh_info] = ssh_info
          end 
          @app.call(env)
        end

        def read_ssh_info(machine)
          return nil if machine.id.nil?

          cached_metadata_file = machine.data_dir.join("cached_metadata")

          @logger.info("Loading cached metadata from #{cached_metadata_file}")
          server = JSON.load(cached_metadata_file.read) rescue nil

          config = machine.provider_config

          host = server.addresses[config.public_network_name].last['addr'] rescue nil

          return {
            :host => host,
            :port => 22,
            :username => config.ssh_username
          }
        end
      end
    end
  end
end
