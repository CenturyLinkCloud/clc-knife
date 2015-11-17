require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcDatacenterList < Knife
      include Knife::ClcBase

      banner 'knife clc datacenter list (options)'

      def run
        $stdout.sync = true

        datacenters = connection.list_datacenters

        puts Formatador.display_table(datacenters, ['id', 'name'])
      end
    end
  end
end
