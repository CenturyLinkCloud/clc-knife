require_relative 'validator'

module Knife
  module Clc
    module Bootstrap
      class Bootstrapper
        attr_reader :cloud_adapter, :config, :errors, :ui

        def initialize(params)
          @cloud_adapter = params.fetch(:cloud_adapter)
          @config = params.fetch(:config)
          @errors = params.fetch(:errors)
          @ui = params.fetch(:ui)
        end

        # TODO: Extract to separate sync bootstrap module
        def sync_bootstrap(server)
          cloud_adapter.ensure_server_powered_on(server)

          command = bootstrap_command

          command.name_args = [get_server_fqdn(server)]

          username, password = config.values_at(:ssh_user, :ssh_password)
          unless username && password
            creds = cloud_adapter.get_server_credentials(server)
            command.config.merge!(:ssh_user => creds['userName'], :ssh_password => creds['password'])
          end

          command.config[:chef_node_name] ||= server['name']

          retry_on_timeouts { command.run }
        end

        def sync_win_bootstrap(server)
          cloud_adapter.ensure_server_powered_on(server)
          command = bootstrap_windows_command

          username, password = config.values_at(:winrm_user, :winrm_password)
          command.config[:winrm_user] = username
          command.config[:winrm_password] = password

          unless username && password
            creds = cloud_adapter.get_server_credentials(server)
            command.config.merge!(:winrm_user => creds['userName'], :winrm_password => creds['password'])
          end

          command.name_args = [get_server_fqdn(server)]
          command.config[:chef_node_name] ||= server['name']

          retry_on_timeouts { command.run }
        end

        # TODO: Extract to separate async bootstrap module
        def add_bootstrapping_params(launch_params)
          launch_params['packages'] ||= []
          if config[:clc_bootstrap_platform] == 'linux'
            launch_params['packages'] << package_for_async_bootstrap
          else
            launch_params['packages'].push(*package_for_async_windows_bootstrap)
          end
        end

        def prepare
          validator.validate
        end

        def enable_winrm_package
          {
            'packageId' => 'a5d9d04369df4276a4f98f2ca7f7872b',
            'parameters' => {
              'Mode' => 'PowerShell',
              'Script' => "
                winrm set winrm/config/service/auth '@{Basic=\"true\"}'
                winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'
              "
            }
          }
        end

        private

        def validator
          @validator ||= Validator.new(
            :connection => cloud_adapter.connection,
            :config => config,
            :errors => errors
          )
        end

        # TODO: Sync module
        def retry_on_timeouts(tries = 2, &block)
          yield
        rescue Errno::ETIMEDOUT => e
          tries -= 1

          if tries > 0
            ui.info 'Retrying host connection...'
            retry
          else
            raise
          end
        end

        # TODO: Sync module
        def get_server_fqdn(server)
          if indirect_bootstrap?
            cloud_adapter.get_private_ip(server)
          else
            cloud_adapter.get_public_ip(server)
          end
        end

        # TODO: Sync module
        def indirect_bootstrap?
          config[:clc_bootstrap_private] || config[:ssh_gateway]
        end

        # TODO: Async module
        def package_for_async_bootstrap
          {
            'packageId' => 'a5d9d04369df4276a4f98f2ca7f7872b',
            'parameters' => {
              'Mode' => 'Ssh',
              'Script' => bootstrap_command.render_template
            }
          }
        end

        # TODO: Async module
        def package_for_async_windows_bootstrap
          require 'chef/knife/bootstrap_windows_base'
          klass = Chef::Knife::BootstrapWindowsSsh
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

        # TODO: Async module
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

        # TODO: Seems like generic part for both sync and async
        def bootstrap_command
          bootstrap_command_class.load_deps
          command = bootstrap_command_class.new
          command.config.merge!(config)
          command.configure_chef
          command
        end

       def bootstrap_windows_command
        if config[:bootstrap_protocol] == "winrm"
          command = Chef::Knife::BootstrapWindowsWinrm.new
        elsif config[:bootstrap_protocol] == "ssh"
          command = Chef::Knife::BootstrapWindowsSsh.new
        end
      end

        # TODO: Should be parametrized to support windows & linux
        def bootstrap_command_class
          Chef::Knife::Bootstrap
        end
      end
    end
  end
end
