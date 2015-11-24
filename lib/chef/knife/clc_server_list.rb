require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerList < Knife
      include Knife::ClcBase

      banner 'knife clc server list (options)'

      option :clc_datacenter,
        :long => '--datacenter VALUE',
        :description => 'Short string representing the data center you are querying'

      option :clc_all,
        :long => '--all',
        :boolean => true,
        :default => false,
        :description => 'The attribute to return a list of all servers from all datacenters'

      def run
        $stdout.sync = true
        validate!
        render
      end

      def collection
        if config[:clc_datacenter]
          connection.list_servers(config[:clc_datacenter])
        elsif config[:clc_all]
          datacenters = connection.list_datacenters

          datacenters.map do |dc|
            connection.list_servers(dc['id'])
          end.flatten
        end
      end

      def headers
        {
          'id' => 'ID',
          'name' => 'Name',
          'description' => 'Description',
          'groupId' => 'Group ID',
          'osType' => 'OS Type',
          'status' => 'Status',
          'locationId' => 'Location ID'
        }
      end

      def fields
        %w(id name description groupId locationId osType status)
      end

      def filters
        {
          'description' => proc { |desc| desc.empty? ? '-' : desc }
        }
      end

      def render
        output = Hirb::Helpers::AutoTable.render(collection,
          :headers => headers,
          :fields => fields,
          :filters => filters,
          :resize => false)

        puts output
      end

      def validate!
        if config[:clc_datacenter].nil? && !config[:clc_all]
          errors << 'Datacenter ID is required'
        end

        check_for_errors!
      end
    end
  end
end
