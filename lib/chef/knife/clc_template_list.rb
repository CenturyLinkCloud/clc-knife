require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcTemplateList < Knife
      include Knife::ClcBase

      banner 'knife clc template list (options)'

      def run
        $stdout.sync = true

        templates = connection.list_templates('ca1').sort { |a, b| a['osType'] <=> b['osType'] }

        headers = {
          'name' => 'Name',
          'osType' => 'OS Type',
          'description' => 'Description',
          'storageSizeGB' => 'Storage',
          'capabilities' => 'Capabilities',
          'apiOnly' => 'Api Only'
        }

        fields = headers.keys

        filters = {
          'storageSizeGB' => ->(size) { "#{size} GB".rjust(7) },
          'apiOnly' => ->(api_flag) { (api_flag ? '+' : '-').center(9) },
          'capabilities' => ->(capabilities) { capabilities.empty? ? '-' : capabilities.join(', ') }
        }

        max_fields = {
          'description' => 0.2,
          'storageSizeGB' => 7,
          'capabilities' => 25,
          'apiOnly' => 9
        }

        puts Hirb::Helpers::AutoTable.render(templates, {
          :headers => headers,
          :fields => fields,
          :filters => filters,
          :max_fields => max_fields,
          :resize => false
        })
      end
    end
  end
end
