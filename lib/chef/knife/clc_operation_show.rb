require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcOperationShow < Knife
      include Knife::ClcBase

      banner 'knife clc operation show ID (options)'

      option :clc_wait,
        :long => '--wait',
        :description => 'Wait for operation completion',
        :boolean => true,
        :default => false

      def parse_and_validate_parameters
        unless name_args[0]
          errors << 'Operation ID is required'
        end
      end

      def execute
        operation_id = name_args[0]

        if config[:clc_wait]
          ui.info 'Waiting for operation completion...'
          connection.wait_for(operation_id) { putc '.' }
          ui.info "\n"
          ui.info 'Operation has been completed'
        else
          status = connection.show_operation(operation_id)['status']
          ui.info "#{ui.color('Status', :bold)}: #{status}"
        end
      end
    end
  end
end
