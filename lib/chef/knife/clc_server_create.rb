require 'chef/knife/clc_server_show'

require 'knife-clc/base'
require 'knife-clc/async'
require 'knife-clc/cloud_extensions'
require 'knife-clc/server_launch'
require 'knife-clc/bootstrap'
require 'knife-clc/ip_assignment'

class Chef
  class Knife
    class ClcServerCreate < Knife
      include ::Knife::Clc::Base
      include ::Knife::Clc::Async
      include ::Knife::Clc::CloudExtensions
      include ::Knife::Clc::ServerLaunch
      include ::Knife::Clc::IpAssignment
      include ::Knife::Clc::Bootstrap

      banner 'knife clc server create (options)'

      def parse_and_validate_parameters
        server_launcher.prepare
        ip_assigner.prepare
        bootstrapper.prepare
      end

      def execute
        config[:clc_wait] ? sync_create_server : async_create_server
      end

      def sync_create_server
        ui.info 'Requesting server launch...'

        # TODO AS: Hide inside of sync bootstrap stuff...
        # TODO AS: Block is no longer supported
        if config[:clc_bootstrap] && config[:clc_bootstrap_platform] == 'windows' && knife_running_on_linux?
          links = server_launcher.execute do |launch_params|
            launch_params["packages"] ||= []
            launch_params["packages"] << bootstrapper.enable_winrm_package
          end
        else
          links = server_launcher.execute
        end

        connection.wait_for(links['operation']['id']) { putc '.' }
        ui.info "\n"
        ui.info "Server has been launched"

        server = connection.follow(links['resource'])

        if config[:clc_allowed_protocols]
          ui.info 'Requesting public IP...'
          ip_links = ip_assigner.execute(server['id'])
          connection.wait_for(ip_links['operation']['id']) { putc '.' }
          ui.info "\n"
          ui.info 'Public IP has been assigned'
          server = connection.follow(links['resource'])
        end

        if config[:clc_bootstrap]
          bootstrapper.sync_bootstrap(server)
        end

        argv = [links['resource']['id'], '--uuid', '--creds']
        if config[:clc_allowed_protocols]
          argv << '--ports'
        end

        if (username = config[:clc_username]) && (password = config[:clc_password])
          argv.concat(['--username', username, '--password', password])
        end

        Chef::Knife::ClcServerShow.new(argv).run
      end

      def async_create_server
        if config[:clc_bootstrap]
          bootstrapper.async_bootstrap(server_launcher.launch_parameters)
          ui.info 'Bootstrap has been scheduled'
        end

        ui.info 'Requesting server launch...'
        links = server_launcher.execute
        ui.info 'Launch request has been sent'
        ui.info "You can check launch operation status with 'knife clc operation show #{links['operation']['id']}'"

        if config[:clc_allowed_protocols]
          ui.info 'Requesting public IP...'
          server = connection.follow(links['resource'])
          ip_links = ip_assigner.execute(server['id'])
          ui.info 'Public IP request has been sent'
          ui.info "You can check assignment operation status with 'knife clc operation show #{ip_links['operation']['id']}'"
        end

        argv = [links['resource']['id'], '--uuid', '--creds']
        argv << '--ports' if config[:clc_allowed_protocols]

        ui.info "You can check server status later with 'knife clc server show #{argv.join(' ')}'"
      end
    end
  end
end
