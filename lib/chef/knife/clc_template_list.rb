require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcTemplateList < Knife
      include Knife::ClcBase

      banner 'knife clc template list (options)'

      option :clc_datacenter,
        :long => '--datacenter ID',
        :short => '-D ID',
        :description => 'Datacenter ID to show templates from',
        :on => :head

      option :clc_all,
        :long => '--all',
        :boolean => true,
        :default => false,
        :description => 'The attribute to return a list of all templates from all datacenters',
        :on => :head

      def execute
        context[:templates] = cloud_templates
        render
      end

      def cloud_templates
        if config[:clc_datacenter]
          connection.list_templates(config[:clc_datacenter])
        elsif config[:clc_all]
          datacenters = connection.list_datacenters

          datacenters.map do |dc|
            connection.list_templates(dc['id'])
          end.flatten
        end
      end

      def parse_and_validate_parameters
        if config[:clc_datacenter].nil? && !config[:clc_all]
          errors << 'Datacenter ID is required'
        end
      end

      def filters
        {
          'storageSizeGB' => ->(size) { (size.zero? ? '-' : "#{size} GB").rjust(7) },
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

      def render
        ui.info Hirb::Helpers::AutoTable.render(context[:templates],
          :headers => headers,
          :fields => fields,
          :filters => filters,
          :max_fields => width_limits,
          :resize => false,
          :description => false)
      end
    end
  end
end
