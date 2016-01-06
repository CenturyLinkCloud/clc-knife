require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerList < Knife
      include Knife::ClcBase

      banner 'knife clc server list (options)'

      option :clc_datacenter,
        :long => '--datacenter ID',
        :description => 'Short string representing the data center you are querying',
        :on => :head

      option :clc_all,
        :long => '--all',
        :boolean => true,
        :default => false,
        :description => 'The attribute to return a list of all servers from all datacenters',
        :on => :head

      option :clc_chef_nodes,
        :long => '--chef-nodes',
        :boolean => true,
        :default => false,
        :description => 'Wherever to include Chef node names in the listing or not',
        :on => :head

      def execute
        servers = cloud_servers
        merge_public_ips!(servers)
        merge_chef_nodes!(servers) if config[:clc_chef_nodes]

        context[:servers] = servers

        render
      end

      def merge_public_ips!(servers)
        servers.map! do |server|
          ip_link = server['links'].find { |link| link['rel'] == 'publicIPAddress' }
          server['publicIP'] = ip_link['id'] if ip_link
          server
        end
      end

      def merge_chef_nodes!(servers)
        nodes = Chef::Node.list(true).values
        servers.map! do |server|
          existing_node = nodes.find { |node| node['machinename'] == server['name'] }
          server['chefNode'] = existing_node.name if existing_node
          server
        end
      end

      def cloud_servers
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
          'publicIP' => 'Public IP',
          'chefNode' => 'Chef Node',
          'groupId' => 'Group',
          'osType' => 'OS Type',
          'status' => 'Status',
          'locationId' => 'DC'
        }
      end

      def fields
        # TODO AS: Displaying shortened list of fields for now
        # default_fields = %w(id name publicIP groupId locationId osType status)
        default_fields = %w(name publicIP status)
        config[:clc_chef_nodes] ? default_fields.insert(3, 'chefNode') : default_fields
      end

      def filters
        {
          'publicIP' => ->(ip) { ip || '-' },
          'chefNode' => ->(name) { name || '-' }
        }
      end

      def width_limits
        {
          'chefNode' => 21,
          'status' => 15
        }
      end

      def render
        ui.info Hirb::Helpers::AutoTable.render(context[:servers],
          :headers => headers,
          :fields => fields,
          :filters => filters,
          :max_fields => width_limits,
          :resize => false,
          :description => false)
      end

      def parse_and_validate_parameters
        if config[:clc_datacenter].nil? && !config[:clc_all]
          errors << 'Datacenter ID is required'
        end
      end
    end
  end
end
