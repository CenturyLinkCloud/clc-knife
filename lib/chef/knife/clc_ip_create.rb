require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcIpCreate < Knife
      include Knife::ClcBase

      banner 'knife clc ip create (options)'

      option :clc_server,
        :long => '--server ID',
        :description => 'ID of the server to assign IP to'

      option :clc_internal_ip,
        :long => '--internal IP',
        :description => 'The internal (private) IP address to map to the new public IP address'

      option :clc_allowed_protocols,
        :long => '--allow PROTOCOL:FROM-TO',
        :description => 'Assigns public IP with permissions for specified protocol',
        :proc => ->(param) do
          Chef::Config[:knife][:clc_allowed_protocols] ||= []
          Chef::Config[:knife][:clc_allowed_protocols] << param
        end

      option :clc_sources,
        :long => '--source CIDR',
        :description => 'The source IP address range allowed to access the new public IP address',
        :proc => ->(param) do
          Chef::Config[:knife][:clc_sources] ||= []
          Chef::Config[:knife][:clc_sources] << param
        end

      option :clc_wait,
        :long => '--wait',
        :description => 'Wait for operation completion',
        :boolean => true,
        :default => false

      attr_accessor :data

      def parse_and_validate_parameters
        unless config[:clc_server]
          errors << 'Server ID is required'
        end

        if config[:clc_allowed_protocols]
          config[:clc_allowed_protocols].map! do |param|
            protocol, port_range = param.split(':', 2)

            case protocol.downcase
            when 'ssh', 'sftp' then { 'protocol' => 'tcp', 'port' => 22 }
            when 'rdp' then { 'protocol' => 'tcp', 'port' => 3389 }
            when 'icmp' then { 'protocol' => 'icmp' }
            when 'http' then [{ 'protocol' => 'tcp', 'port' => 80 }, { 'protocol' => 'tcp', 'port' => 8080 }]
            when 'https' then { 'protocol' => 'tcp', 'port' => 443 }
            when 'ftp' then { 'protocol' => 'tcp', 'port' => 21 }
            when 'ftps' then { 'protocol' => 'tcp', 'port' => 990 }
            when 'udp', 'tcp'
              unless port_range
                errors << "No ports specified for #{param}"
              else
                ports = port_range.split('-').map do |port_string|
                  Integer(port_string) rescue nil
                end

                if ports.any?(&:nil?) || ports.size > 2 || ports.size < 1
                  errors << "Malformed port range for #{param}"
                end

                {
                  'protocol' => protocol.downcase,
                  'port' => ports[0],
                  'portTo' => ports[1]
                }.keep_if { |_, value| value }
              end
            else
              errors << "Unsupported protocol for #{param}"
            end
          end
          config[:clc_allowed_protocols].flatten!
        else
          errors << 'At least one protocol definition is required'
        end

        config[:clc_sources] && config[:clc_sources].map! do |cidr|
          { 'cidr' => cidr }
        end
      end

      def prepare_ip_params
        {
          'ports' => config[:clc_allowed_protocols],
          'sourceRestrictions' => config[:clc_sources],
          'internalIPAddress' => config[:clc_internal_ip]
        }.delete_if { |_, value| value.nil? || value.empty? }
      end

      def execute
        ui.info 'Requesting public IP...'
        links = connection.create_ip_address(config[:clc_server], prepare_ip_params)

        if config[:clc_wait]
          connection.wait_for(links['operation']['id']) { putc '.' }
          ui.info "\n"
          ui.info "Public IP has been assigned"
          ui.info "Loading current IP address configuration..."
          self.data = connection.list_ip_addresses(config[:clc_server])

          render_addresses
        else
          ui.info 'IP assignment request has been sent'
          ui.info "You can check assignment operation status with 'knife clc operation show #{links['operation']['id']}'"
        end
      end

      def fields
        %w(id internalIPAddress ports sourceRestrictions)
      end

      def headers
        {
          'id' => 'Public IP',
          'internalIPAddress' => 'Internal IP',
          'ports' => 'Ports',
          'sourceRestrictions' => 'Sources'
        }
      end

      def filters
        {
          'sourceRestrictions' => ->(sources) { sources.empty? ? '-' : sources.join(', ') },
          'ports' => ->(ports) { ports.map { |port_definition| format_port_definition(port_definition) }.join(', ') }
        }
      end

      def format_port_definition(definition)
        protocol = definition['protocol']

        if %w(tcp udp).include? protocol.downcase
          ports = definition.values_at('port', 'portTo').compact
          [protocol, ports.join('-')].join(':')
        else
          protocol
        end
      end

      def render_addresses
        output = Hirb::Helpers::AutoTable.render(data,
          :headers => headers,
          :fields => fields,
          :filters => filters,
          :resize => false,
          :description => false)

        puts output
      end
    end
  end
end
