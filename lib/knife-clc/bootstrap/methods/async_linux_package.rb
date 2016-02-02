module Knife
  module Clc
    module Bootstrap
      module Methods
        class AsyncLinuxPackage
          attr_reader :config, :subcommand_loader

          def initialize(params)
            @config = params.fetch(:config)
            @subcommand_loader = params.fetch(:subcommand_loader)
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
                'Script' => bootstrap_script
              }
            }]
          end

          def bootstrap_script
            bootstrap_command.render_template
          end

          def bootstrap_command
            subcommand_loader.load(:class => Chef::Knife::Bootstrap, :config => config)
          end
        end
      end
    end
  end
end
