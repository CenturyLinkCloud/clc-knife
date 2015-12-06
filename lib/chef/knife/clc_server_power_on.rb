require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerPowerOn < Knife
      include Knife::ClcBase

      banner 'knife clc server power_on ID (options)'

      option :clc_wait,
        :long => '--wait',
        :description => 'Wait for operation completion',
        :boolean => true,
        :default => false

      def parse_and_validate_parameters
        unless name_args[0]
          errors << 'Server ID is required'
        end
      end

      def execute
        ui.info 'Requesting server power on...'
        links = connection.power_on_server(name_args[0])

        if config[:clc_wait]
          connection.wait_for(links['operation']['id']) { putc '.' }
          ui.info "\n"
          ui.info 'Server has been powered on'
        else
          ui.info 'Power on request has been sent'
          ui.info "You can check power on operation status with 'knife clc operation show #{links['operation']['id']}'"
        end
      end
    end
  end
end
