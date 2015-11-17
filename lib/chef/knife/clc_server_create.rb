require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerCreate < Knife
      include Knife::ClcBase

      banner 'knife clc server create (options)'

      def run
        $stdout.sync = true

        datacenter = connection.create_server
      end
    end
  end
end
