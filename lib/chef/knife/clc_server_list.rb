require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerList < Knife
      include Knife::ClcBase

      banner 'knife clc server list (options)'

      def run
        $stdout.sync = true

        servers = connection.list_servers(name_args[0])

        properties = %w(id name description groupId locationId osType status)

        puts Formatador.display_table(servers, properties)
      end
    end
  end
end
