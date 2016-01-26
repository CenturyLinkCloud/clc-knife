module Knife
  module Clc
    module Bootstrap
      class WindowsSshBootstrapper
        attr_reader :cloud_adapter, :config, :ui

        def initialize(params)
          @cloud_adapter = params.fetch(:cloud_adapter)
          @config = params.fetch(:config)
          @ui = params.fetch(:ui)
        end

        def execute(server)
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

        def package_for_sshd
          {
            'packageId' => 'a5d9d04369df4276a4f98f2ca7f7872b',
            'parameters' => {
              'Mode' => 'PowerShell',
              'Script' => win_sshd_install_script
            }
          }
        end

        private

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

        def win_sshd_install_script
          %Q(
            $url = 'https://bvdl.s3-eu-west-1.amazonaws.com/BvSshServer-Inst.exe';
            $file = 'C:\\BvSshServer-Inst.exe';
            $downloader = New-Object System.Net.WebClient;
            $downloader.DownloadFile($url, $file);
            & $file -instance='WinSSHD' -acceptEULA
            net start BvSshServer
            netsh advfirewall firewall add rule name="WinSSHD" dir=in action=allow protocol=TCP localport=#{config[:ssh_port] || 22}
          )
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

        def bootstrap_command
          require 'chef/knife/bootstrap_windows_base'
          klass = Chef::Knife::BootstrapWindowsSsh
          klass.load_deps
          bootstrap_command = klass.new
          bootstrap_command.config.merge!(config)
          bootstrap_command.configure_chef
          bootstrap_command
        end
      end
    end
  end
end
