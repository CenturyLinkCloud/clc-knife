require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcTemplateList < Knife
      include Knife::ClcBase

      banner 'knife clc template list (options)'

      option :clc_datacenter,
        :long => '--datacenter ID',
        :short => '-D ID',
        :description => 'Datacenter ID to show templates from'

      def run
        $stdout.sync = true
        validate!
        render
      end

      def validate!
        unless config[:clc_datacenter]
          ui.error 'Datacenter option is required'
          show_usage
          exit 1
        end
      end

      def filters
        {
          'storageSizeGB' => ->(size) { "#{size} GB".rjust(7) },
          'apiOnly' => ->(api_flag) { (api_flag ? '+' : '-').center(9) },
          'capabilities' => ->(capabilities) { capabilities.empty? ? '-' : capabilities.join(', ') }
        }
      end

      def width_limits
        {
          'description' => 0.2,
          'storageSizeGB' => 7,
          'capabilities' => 25,
          'apiOnly' => 9
        }
      end

      def fields
        %w(name osType description storageSizeGB capabilities apiOnly)
      end

      def headers
        {
          'name' => 'Name',
          'osType' => 'OS Type',
          'description' => 'Description',
          'storageSizeGB' => 'Storage',
          'capabilities' => 'Capabilities',
          'apiOnly' => 'API Only'
        }
      end

      def collection
        connection.list_templates(config[:clc_datacenter])
      end

      def render
        output = Hirb::Helpers::AutoTable.render(collection,
          :headers => headers,
          :fields => fields,
          :filters => filters,
          :max_fields => width_limits,
          :resize => false,
          :description => false)

        puts output
      end
    end
  end
end
