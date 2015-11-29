require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerDelete < Knife
      include Knife::ClcBase

      option :clc_wait,
        :long => '--wait',
        :description => 'Wait for operation completion',
        :boolean => true,
        :default => false

      banner 'knife clc server delete (options)'

      def run
        $stdout.sync = true

        links = connection.delete_server(name_args[0])
        connection.wait_for(links['operation']) { putc '.' } if config[:clc_wait]
      end
    end
  end
end
