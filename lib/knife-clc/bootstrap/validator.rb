require 'chef/node'

module Knife
  module Clc
    module Bootstrap
      class Validator
        attr_reader :connection, :config, :errors

        def initialize(params)
          @connection = params.fetch(:connection)
          @config = params.fetch(:config)
          @errors = params.fetch(:errors)
        end

        def validate
          return unless config[:clc_bootstrap]

          check_chef_server_connectivity

          if config[:clc_bootstrap_platform]
            validate_bootstrap_platform
          else
            check_server_platform
          end

          check_server_platform
          if config[:clc_wait]
            check_bootstrap_connectivity_params
          else
            check_bootstrap_node_connectivity_params
          end
        end

        private

        def indirect_bootstrap?
          config[:clc_bootstrap_private] || config[:ssh_gateway]
        end

        def check_chef_server_connectivity
          Chef::Node.list
        rescue Exception => e
          errors << 'Could not connect to Chef Server: ' + e.message
        end

        def check_bootstrap_node_connectivity_params
          unless Chef::Config[:validation_key]
            errors << "Validatorless async bootstrap is not supported. Validation key #{Chef::Config[:validation_key]} not found"
          end
        end

        def validate_bootstrap_platform
          unless %w(linux windows).include? config[:clc_bootstrap_platform]
            errors << "Unsupported bootstrap platform: #{config[:clc_bootstrap_platform]}"
          end
        end

        def check_bootstrap_connectivity_params
          return if indirect_bootstrap?

          if public_ip_requested?
            check_connectivity_errors
          else
            errors << 'Bootstrapping requires public IP access to the server. Ignore this check with --bootstrap-private'
          end
        end

        def check_connectivity_errors
          if config[:clc_bootstrap_platform] == 'windows'
            errors << "Bootstrapping requires WinRM access to the server" unless winrm_access_requested?
          else
            errors << "Bootstrapping requires SSH access to the server" unless ssh_access_requested?
          end
        end

        def check_server_platform
          return unless config[:clc_group] && config[:clc_source_server]

          if template = find_source_template
            windows_platform = template['osType'] =~ /windows/
          elsif server = find_source_server
            windows_platform = server['os'] =~ /windows/
          end

          if windows_platform
            config[:clc_bootstrap_platform] = 'windows'
          else
            config[:clc_bootstrap_platform] = 'linux'
          end
        rescue Clc::CloudExceptions::Error => e
          errors << "Could not derive server bootstrap platform: #{e.message}. Please set it manually via --bootstrap-platform"
        end

        def find_source_template
          group = connection.show_group(config[:clc_group])
          datacenter_id = group['locationId']
          connection.list_templates(datacenter_id).find do |template|
            template['name'] == config[:clc_source_server]
          end
        end

        def find_source_server
          connection.show_server(config[:clc_source_server])
        end

        def public_ip_requested?
          config[:clc_allowed_protocols] && config[:clc_allowed_protocols].any?
        end


        def winrm_access_requested?
          winrm_port = requested_winrm_port

          config[:clc_allowed_protocols].find do |permission|
            protocol, from, to = permission.values_at('protocol', 'port', 'portTo')
            next unless protocol == 'tcp'
            next unless from

            to ||= from

            Range.new(from, to).include? winrm_port
          end
        end

        def requested_winrm_port
          (config[:winrm_port] && Integer(config[:winrm_port])) || 5985
        end

        def ssh_access_requested?
          ssh_port = requested_ssh_port

          config[:clc_allowed_protocols].find do |permission|
            protocol, from, to = permission.values_at('protocol', 'port', 'portTo')
            next unless protocol == 'tcp'
            next unless from

            to ||= from

            Range.new(from, to).include? ssh_port
          end
        end

        def requested_ssh_port
          (config[:ssh_port] && Integer(config[:ssh_port])) || 22
        end
      end
    end
  end
end
