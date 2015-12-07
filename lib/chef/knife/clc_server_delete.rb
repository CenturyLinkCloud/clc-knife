require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerDelete < Knife
      include Knife::ClcBase

      banner 'knife clc server delete ID (options)'

      option :clc_wait,
        :long => '--wait',
        :description => 'Wait for operation completion',
        :boolean => true,
        :default => false,
        :on => :head

      def parse_and_validate_parameters
        unless name_args[0]
          errors << 'Server ID is required'
        end
      end

      def execute
        ui.info 'Requesting server deletion...'
        links = connection.delete_server(name_args[0])

        if config[:clc_wait]
          connection.wait_for(links['operation']['id']) { putc '.' }
          ui.info "\n"
          ui.info 'Server has been deleted'
        else
          ui.info 'Deletion request has been sent'
          ui.info "You can check deletion operation status with 'knife clc operation show #{links['operation']['id']}'"
        end
      end
    end
  end
end
