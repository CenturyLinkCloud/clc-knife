require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcIpDelete < Knife
      include Knife::ClcBase

      banner 'knife clc ip delete IP (options)'

      option :clc_server,
        :long => '--server ID',
        :description => 'ID of the server to assign IP to'

      option :clc_wait,
        :long => '--wait',
        :description => 'Wait for operation completion',
        :boolean => true,
        :default => false

      def parse_and_validate_parameters
        unless name_args[0]
          errors << 'IP string is required'
        end

        unless config[:clc_server]
          errors << 'Server ID is required'
        end
      end

      def execute
        ui.info 'Requesting IP deletion...'
        links = connection.delete_ip_address(config[:clc_server], name_args[0])

        if config[:clc_wait]
          connection.wait_for(links['operation']['id']) { putc '.' }
          ui.info "\n"
          ui.info 'IP has been deleted'
        else
          ui.info 'Deletion request has been sent'
          ui.info "You can check deletion operation status with 'knife clc operation show #{links['operation']['id']}'"
        end
      end
    end
  end
end
