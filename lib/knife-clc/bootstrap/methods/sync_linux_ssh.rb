module Knife
  module Clc
    module Bootstrap
      module Methods
        class SyncLinuxSsh
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
            wait_for_sshd(fqdn)

            command = subcommand_loader.load(:class => Chef::Knife::Bootstrap, :config => config)

            username, password = config.values_at(:ssh_user, :ssh_password)
            unless username && password
              creds = cloud_adapter.get_server_credentials(server)
              command.config.merge!(:ssh_user => creds['userName'], :ssh_password => creds['password'])
            end

            command.name_args = [fqdn]
            command.config[:chef_node_name] ||= server['name']

            command.run
          end

          private

          def wait_for_sshd(hostname)
            expire_at = Time.now + 30
            port = config[:ssh_port] || 22

            if gateway = config[:ssh_gateway]
              until connectivity_helper.test_ssh_tunnel(:host => hostname, :port => port, :gateway => gateway)
                raise 'Could not establish tunneled SSH connection with the server' if Time.now > expire_at
              end
            else
              until connectivity_helper.test_tcp(:host => hostname, :port => port)
                raise 'Could not establish SSH connection with the server' if Time.now > expire_at
              end
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
            config[:clc_bootstrap_private] || config[:ssh_gateway]
          end
        end
      end
    end
  end
end
