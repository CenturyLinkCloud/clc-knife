require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerDelete < Knife
      include Knife::ClcBase

      banner 'knife clc server delete (options)'

      def run
        $stdout.sync = true

        datacenter = connection.delete_server(name_args[0])
      end
    end
  end
end
