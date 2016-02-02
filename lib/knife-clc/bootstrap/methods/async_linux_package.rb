module Knife
  module Clc
    module Bootstrap
      module Methods
        class AsyncLinuxPackage
          attr_reader :config

          def initialize(params)
            @config = params.fetch(:config)
          end

          def execute(launch_parameters)
            launch_parameters['packages'] ||= []
            launch_parameters['packages'].concat(packages_for_async_bootstrap)
          end

          private

          def packages_for_async_bootstrap
            [{
              'packageId' => 'a5d9d04369df4276a4f98f2ca7f7872b',
              'parameters' => {
                'Mode' => 'Ssh',
                'Script' => bootstrap_command.render_template
              }
            }]
          end

          def bootstrap_command
            bootstrap_command_class.load_deps
            command = bootstrap_command_class.new
            command.config.merge!(config)
            command.configure_chef
            command
          end

          def bootstrap_command_class
            Chef::Knife::Bootstrap
          end
        end
      end
    end
  end
end
