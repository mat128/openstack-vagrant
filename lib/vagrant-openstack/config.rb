require "vagrant"

module VagrantPlugins
  module OpenStack
    class Config < Vagrant.plugin("2", :config)
      # The API key to access OpenStack.
      #
      # @return [String]
      attr_accessor :api_key

      # The endpoint to access OpenStack.
      #
      # @return [String]
      attr_accessor :endpoint

      # Openstack region, if your openstack instance uses these.
      # Rackspace typically uses these. You need to provide their three letter acronym (for example: DFW)
      # @return [String]
      attr_accessor :region

      # The flavor of server to launch, either the ID or name. This
      # can also be a regular expression to partially match a name.
      attr_accessor :flavor

      # The name or ID of the image to use. This can also be a regular
      # expression to partially match a name.
      attr_accessor :image

      # The name of the server. This defaults to the name of the machine
      # defined by Vagrant (via `config.vm.define`), but can be overriden
      # here.
      attr_accessor :server_name

      # The username to access OpenStack.
      #
      # @return [String]
      attr_accessor :username
      
      # The name of the keypair to use.
      #
      # @return [String]
      attr_accessor :keypair_name

      # The SSH username to use with this OpenStack instance. This overrides
      # the `config.ssh.username` variable.
      #
      # @return [String]
      attr_accessor :ssh_username

      # User data to be sent to the newly created OpenStack instance. Use this
      # e.g. to inject a script at boot time.
      #
      # @return [String]
      attr_accessor :user_data

      # @return [String]
      attr_accessor :public_network_name

      # @return [String]
      attr_accessor :additional_networks

      def initialize
        @api_key  = UNSET_VALUE
        @endpoint = UNSET_VALUE
        @region = UNSET_VALUE
        @flavor   = UNSET_VALUE
        @image    = UNSET_VALUE
        @server_name = UNSET_VALUE
        @username = UNSET_VALUE
        @keypair_name = UNSET_VALUE
        @ssh_username = UNSET_VALUE
        @user_data = UNSET_VALUE
        @public_network_name = UNSET_VALUE
        @additional_networks = UNSET_VALUE
      end

      def finalize!
        @api_key  = nil if @api_key == UNSET_VALUE
        @endpoint = nil if @endpoint == UNSET_VALUE
        @region = nil if @region == UNSET_VALUE
        @flavor   = /m1.tiny/ if @flavor == UNSET_VALUE
        @image    = /cirros/ if @image == UNSET_VALUE
        @server_name = nil if @server_name == UNSET_VALUE
        @username = nil if @username == UNSET_VALUE

        # Keypair defaults to nil
        @keypair_name = nil if @keypair_name == UNSET_VALUE
        
        # The SSH values by default are nil, and the top-level config
        # `config.ssh` values are used.
        @ssh_username = nil if @ssh_username == UNSET_VALUE

        @user_data = "" if @user_data == UNSET_VALUE

        @public_network_name = "public" if @public_network_name == UNSET_VALUE
        @additional_networks = [] if @additional_networks == UNSET_VALUE
      end

      def validate(machine)
        errors = []

        errors << I18n.t("vagrant_openstack.config.api_key_required") if !@api_key
        errors << I18n.t("vagrant_openstack.config.username_required") if !@username
        
        { "OpenStack Provider" => errors }
      end
    end
  end
end
