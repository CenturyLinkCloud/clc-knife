module Knife
  module Clc
    module Bootstrap
      module Methods
        class AsyncWindowsPackage
          def initialize(params)
            @config = params.fetch(:config)
          end

          def execute(launch_parameters)
            launch_parameters['packages'] ||= []
            launch_parameters['packages'].concat(packages_for_async_bootstrap)
          end

          private

          def packages_for_async_bootstrap
            require 'chef/knife/bootstrap_windows_winrm'
            klass = Chef::Knife::BootstrapWindowsWinrm
            klass.load_deps
            bootstrap_command = klass.new
            bootstrap_command.config.merge!(config)
            bootstrap_command.configure_chef

            script = bootstrap_command.render_template(bootstrap_command.load_template(config[:bootstrap_template]))

            parts = split_script(script)

            parts.map do |part|
              {
                'packageId' => 'a5d9d04369df4276a4f98f2ca7f7872b',
                'parameters' => {
                  'Mode' => 'PowerShell',
                  'Script' => part
                }
              }
            end
          end

          def split_script(script)
            batch_size = 100

            partial_scripts = script.lines.each_slice(batch_size).map do |lines|
              part = "$script = @'\n" +
                lines.join('') +
                "'@\n" +
                "$script | out-file C:\\bootstrap.bat -Append -Encoding ASCII\n"

              part.gsub("\n", "\r\n")
            end

            partial_scripts << 'C:\bootstrap.bat'
          end

          def bootstrap_command
            bootstrap_command_class.load_deps
            command = bootstrap_command_class.new
            command.config.merge!(config)
            command.configure_chef
            command
          end

          def bootstrap_command_class
            Chef::Knife::BootstrapWindowsWinrm
          end
        end
      end
    end
  end
end
