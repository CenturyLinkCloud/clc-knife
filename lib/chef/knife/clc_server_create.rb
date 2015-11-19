require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerCreate < Knife
      include Knife::ClcBase

      banner 'knife clc server create (options)'

      def run
        $stdout.sync = true

        connection.create_server(
          'name' => 'req',
          'groupId' => '975a79f94b84452ea1c920325967a33c',
          'sourceServerId' => 'CENTOS-6-64-TEMPLATE',
          'cpu' => 1,
          'memoryGB' => 1,
          'type' => 'standard'
        )
      end
    end
  end
end
