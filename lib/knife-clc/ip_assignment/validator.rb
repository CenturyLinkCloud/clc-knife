module Knife
  module Clc
    module IpAssignment
      class Validator
        attr_reader :config, :errors

        def initialize(params)
          @config = params.fetch(:config)
          @errors = params.fetch(:errors)
        end

        def validate
          parse_protocol_permissions
          parse_sources
        end

        private

        def parse_protocol_permissions
          permissions = config[:clc_allowed_protocols]
          config[:requested_protocols] = permissions.dup

          return unless permissions && permissions.any?

          permissions.map! do |param|
            protocol, port_range = param.split(':', 2)

            case protocol.downcase
            when 'ssh', 'sftp' then { 'protocol' => 'tcp', 'port' => 22 }
            when 'rdp' then { 'protocol' => 'tcp', 'port' => 3389 }
            when 'icmp' then { 'protocol' => 'icmp' }
            when 'http' then [{ 'protocol' => 'tcp', 'port' => 80 }, { 'protocol' => 'tcp', 'port' => 8080 }]
            when 'https' then { 'protocol' => 'tcp', 'port' => 443 }
            when 'ftp' then { 'protocol' => 'tcp', 'port' => 21 }
            when 'ftps' then { 'protocol' => 'tcp', 'port' => 990 }
            when 'winrm' then [{ 'protocol' => 'tcp', 'port' => 5985 }, { 'protocol' => 'tcp', 'port' => 5986 }]
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

          permissions.flatten!
        end

        def parse_sources
          sources = config[:clc_sources]

          return unless sources && sources.any?

          sources.map! do |cidr|
            { 'cidr' => cidr }
          end
        end
      end
    end
  end
end
