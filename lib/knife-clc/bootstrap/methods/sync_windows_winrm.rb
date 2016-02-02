module Knife
  module Clc
    module Bootstrap
      module Methods
        class SyncWindowsWinrm
          attr_reader :cloud_adapter, :config, :connectivity_helper, :subcommand_loader

          def initialize(params)
            @cloud_adapter = params.fetch(:cloud_adapter)
            @config = params.fetch(:config)
            @connectivity_helper = params.fetch(:connectivity_helper)
            @subcommand_loader = params.fetch(:subcommand_loader)
          end

          def execute(server)
            cloud_adapter.ensure_server_powered_on(server)

            fqdn = get_server_fqdn(server)
            wait_for_winrm(fqdn)

            command = subcommand_loader.load(Chef::Knife::BootstrapWindowsWinrm)

            username, password = config.values_at(:winrm_user, :winrm_password)
            unless username && password
              creds = cloud_adapter.get_server_credentials(server)
              command.config.merge!(:winrm_user => creds['userName'], :winrm_password => creds['password'])
            end

            command.name_args = [fqdn]
            command.config[:chef_node_name] ||= server['name']

            command.run
          end

          private

          def wait_for_winrm(hostname)
            expire_at = Time.now + 3600
            port = config[:winrm_port] || 5985

            until connectivity_helper.test_tcp(:host => hostname, :port => port)
              raise 'Could not establish WinRM connection with the server' if Time.now > expire_at
            end
          end

          def get_server_fqdn(server)
            if indirect_bootstrap?
              cloud_adapter.get_private_ip(server)
            else
              cloud_adapter.get_public_ip(server)
            end
          end

          def indirect_bootstrap?
            config[:clc_bootstrap_private]
          end
        end
      end
    end
  end
end
