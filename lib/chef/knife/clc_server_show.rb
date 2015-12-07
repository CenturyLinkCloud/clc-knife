require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerShow < Knife
      include Knife::ClcBase

      banner 'knife clc server show ID (options)'

      option :clc_uuid,
        :long => '--uuid',
        :description => 'Use primary argument as server UUID instead of just ID',
        :boolean => true,
        :default => false,
        :on => :head

      option :clc_creds,
        :long => '--creds',
        :description => 'Show server credentials',
        :boolean => true,
        :default => false,
        :on => :head

      option :clc_ports,
        :long => '--ports',
        :description => 'Show opened ports and restrictions',
        :boolean => true,
        :default => false,
        :on => :head

      def parse_and_validate_parameters
        unless name_args[0]
          errors << 'Server ID is required'
        end
      end

      def execute
        ui.info 'Requesting server info...'

        context[:server] = get_server
        context[:creds] = get_creds if config[:clc_creds]
        context[:ip_addresses] = get_ip_addresses if config[:clc_ports]

        render
      end

      def get_server
        server = connection.show_server(name_args[0], config[:clc_uuid])

        server['details'] ||= {}
        server['details'].tap do |details|
          details['ipAddresses'] ||= []
          public_ips = server['details']['ipAddresses'].map { |addr| addr['public'] }.compact
          private_ips = server['details']['ipAddresses'].map { |addr| addr['internal'] }.compact
          details.merge!('publicIps' => public_ips, 'privateIps' => private_ips)
        end

        server
      end

      def get_creds
        creds_link = context[:server]['links'].find { |link| link['rel'] == 'credentials' }
        connection.follow(creds_link) if creds_link
      end

      def get_ip_addresses
        context[:ip_addresses] = connection.list_ip_addresses(context[:server]['id'])
      end

      def render
        render_properties
        render_creds if config[:clc_creds]
        render_addresses if config[:clc_ports]
      end

      def server_properties
        %w(id name description groupId locationId osType status)
      end

      def server_detail_properties
        %w(powerState cpu memoryMB storageGB publicIps privateIps)
      end

      def property_labels
        {
          'id' => 'ID',
          'name' => 'Name',
          'description' => 'Description',
          'groupId' => 'Group',
          'locationId' => 'Location',
          'osType' => 'OS Type',
          'cpu' => 'CPUs',
          'memoryMB' => 'Memory',
          'storageGB' => 'Storage',
          'status' => 'Status',
          'powerState' => 'Power State',
          'publicIps' => 'Public IPs',
          'privateIps' => 'Private IPs',
          'userName' => 'Username',
          'password' => 'Password'
        }
      end

      def property_filters
        {
          'description' => ->(description) { description.empty? ? '-' : description },
          'memoryMB' => ->(memory) { "#{memory} MB" },
          'storageGB' => ->(storage) { "#{storage} GB" },
          'publicIps' => ->(ips) { ips.empty? ? '-' : ips.join(', ') },
          'privateIps' => ->(ips) { ips.empty? ? '-' : ips.join(', ') }
        }
      end

      def render_properties
        server = context[:server]

        render_fields(:fields => server_properties, :container => server)
        render_fields(:fields => server_detail_properties, :container => server['details'])
      end

      def render_addresses
        if context[:ip_addresses].empty?
          ui.info 'No additional networking info available'
        else
          ui.info Hirb::Helpers::AutoTable.render(context[:ip_addresses],
            :headers => ip_headers,
            :fields => ip_fields,
            :filters => ip_filters,
            :resize => false,
            :description => false)
        end
      end

      def ip_fields
        %w(id internalIPAddress ports sourceRestrictions)
      end

      def ip_headers
        {
          'id' => 'Public IP',
          'internalIPAddress' => 'Internal IP',
          'ports' => 'Ports',
          'sourceRestrictions' => 'Sources'
        }
      end

      def ip_filters
        {
          'sourceRestrictions' => ->(sources) { sources.empty? ? '-' : sources.map { |source| source['cidr'] }.join(', ') },
          'ports' => ->(ports) { ports.map { |permission| format_permission(permission) }.join(', ') }
        }
      end

      def format_permission(permission)
        protocol = permission['protocol']

        if %w(tcp udp).include? protocol.downcase
          ports = permission.values_at('port', 'portTo').compact
          [protocol, ports.join('-')].join(':')
        else
          protocol
        end
      end

      def render_creds
        render_fields(fields: %w(userName password), container: context[:creds] || {})
      end


      def render_fields(fields: [], labels: property_labels, filters: property_filters, container: {})
        fields.each do |field|
          value = container[field]
          filter = filters[field]

          formatted_value = if value
            filter ? filter.call(value) : value
          else
            '-'
          end

          label = labels[field] || field

          ui.info "#{ui.color(label + ':', :bold)} #{formatted_value}"
        end
      end
    end
  end
end
