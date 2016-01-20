require_relative 'validator'

module Knife
  module Clc
    module Bootstrap
      class Bootstrapper
        extend Forwardable

        def_delegator :validator, :validate

        attr_reader :connection, :config, :errors, :ui

        def initialize(params)
          @connection = params.fetch(:connection)
          @config = params.fetch(:config)
          @errors = params.fetch(:errors)
          @ui = params.fetch(:ui)
        end

        # Sync stuff
        def sync_bootstrap(uuid)
          server = connection.show_server(uuid, true)

          ensure_server_powered_on(server)

          command = bootstrap_command

          command.name_args = [get_server_fqdn(server)]

          username, password = config.values_at(:ssh_user, :ssh_password)
          unless username && password
            creds = get_server_credentials(server)
            command.config.merge!(:ssh_user => creds['userName'], :ssh_password => creds['password'])
          end

          command.config[:chef_node_name] ||= server['name']

          retry_on_timeouts { command.run }
        end

        private

        def validator
          @validator ||= Validator.new(
            :connection => connection,
            :config => config,
            :errors => errors
          )
        end

        # Async stuff
        def add_bootstrapping_params(launch_params)
          launch_params['packages'] ||= []
          if config[:clc_bootstrap_platform] == 'linux'
            launch_params['packages'] << package_for_async_bootstrap
          else
            launch_params['packages'].push(*package_for_async_windows_bootstrap)
          end
        end

        # Sync stuff
        def ensure_server_powered_on(server)
          return unless server['details']['powerState'] == 'stopped'
          ui.info 'Requesting server power on...'
          links = connection.power_on_server(server['id'])
          connection.wait_for(links['operation']['id']) { putc '.' }
          ui.info "\n"
          ui.info 'Server has been powered on'
        end

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

        def get_server_fqdn(server)
          if indirect_bootstrap?
            private_ips = server['details']['ipAddresses'].map { |addr| addr['internal'] }.compact
            private_ips.first
          else
            public_ips = server['details']['ipAddresses'].map { |addr| addr['public'] }.compact
            public_ips.first
          end
        end

        def indirect_bootstrap?
          config[:clc_bootstrap_private] || config[:ssh_gateway]
        end

        def get_server_credentials(server)
          creds_link = server['links'].find { |link| link['rel'] == 'credentials' }
          connection.follow(creds_link) if creds_link
        end

        # Async stuff
        def package_for_async_bootstrap
          {
            'packageId' => 'a5d9d04369df4276a4f98f2ca7f7872b',
            'parameters' => {
              'Mode' => 'Ssh',
              'Script' => bootstrap_command.render_template
            }
          }
        end

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

        # Validations, checks and config parsing stuff
        def indirect_bootstrap?
          config[:clc_bootstrap_private] || config[:ssh_gateway]
        end

        # Probably generic stuff
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
