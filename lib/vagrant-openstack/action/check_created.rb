module VagrantPlugins
  module OpenStack
    module Action
      class CheckCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].state.id != :not_created
            raise Vagrant::Errors::VMNotCreatedError
          end
          @app.call(env)
        end
      end
    end
  end
end
