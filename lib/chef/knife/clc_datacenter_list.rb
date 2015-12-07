require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcDatacenterList < Knife
      include Knife::ClcBase

      banner 'knife clc datacenter list (options)'

      def execute
        context[:datacenters] = connection.list_datacenters
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

      def render
        ui.info Hirb::Helpers::AutoTable.render(context[:datacenters],
          :fields => fields,
          :headers => headers,
          :resize => false,
          :description => false)
      end
    end
  end
end
