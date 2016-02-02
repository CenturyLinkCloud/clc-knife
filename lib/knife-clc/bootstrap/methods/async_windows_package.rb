require 'chef/knife/bootstrap_windows_winrm'

module Knife
  module Clc
    module Bootstrap
      module Methods
        class AsyncWindowsPackage
          COMBINED_SCRIPT_PATH = 'C:/bootstrap.bat'
          LINES_PER_PARTIAL_SCRIPT = 100

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
            split_script(bootstrap_script).map do |partial_script|
              {
                'packageId' => 'a5d9d04369df4276a4f98f2ca7f7872b',
                'parameters' => {
                  'Mode' => 'PowerShell',
                  'Script' => partial_script
                }
              }
            end
          end

          def split_script(script)
            partial_scripts = script.lines.each_slice(LINES_PER_PARTIAL_SCRIPT).map do |lines|
              appending_script(lines.join).tap { |script| ensure_windows_newlines(script) }
            end

            partial_scripts.push(COMBINED_SCRIPT_PATH)
          end

          def appending_script(script_to_append)
            "$script = @'\n" +
            script_to_append +
            "'@\n" +
            "$script | out-file #{COMBINED_SCRIPT_PATH} -Append -Encoding ASCII\n"
          end

          def ensure_windows_newlines(script)
            script.gsub!("\r\n", "\n")
            script.gsub!("\n", "\r\n")
          end

          def bootstrap_command
            subcommand_loader.load(:class => Chef::Knife::BootstrapWindowsWinrm, :config => config)
          end

          def bootstrap_script
            command = bootstrap_command
            command.render_template(command.load_template(config[:bootstrap_template]))
          end
        end
      end
    end
  end
end
