require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerPowerOff < Knife
      include Knife::ClcBase

      option :clc_wait,
        :long => '--wait',
        :description => 'Wait for operation completion',
        :boolean => true,
        :default => false

      banner 'knife clc server power_off ID (options)'

      def parse_and_validate_parameters
        unless name_args[0]
          errors << 'Server ID is required'
        end
      end

      def execute
        ui.info 'Requesting server power off...'
        links = connection.power_off_server(name_args[0])

        if config[:clc_wait]
          connection.wait_for(links['operation']['id']) { putc '.' }
          ui.info "\n"
          ui.info 'Server has been powered off'
        else
          ui.info 'Power off request has been sent'
          ui.info "You can check power off operation status with 'knife clc operation show #{links['operation']['id']}'"
        end
      end
    end
  end
end
