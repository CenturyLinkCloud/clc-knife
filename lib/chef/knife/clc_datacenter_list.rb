require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcDatacenterList < Knife
      include Knife::ClcBase

      banner 'knife clc datacenter list (options)'

      def run
        $stdout.sync = true
        render
      end

      def fields
        %w(name id)
      end

      def headers
        {
          'name' => 'Name',
          'id' => 'ID'
        }
      end

      def data
        connection.list_datacenters
      end

      def render
        output = Hirb::Helpers::AutoTable.render(data,
          :fields => fields,
          :headers => headers,
          :resize => false,
          :description => false)

        puts output
      end
    end
  end
end
