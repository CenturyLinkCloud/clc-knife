require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerCreate < Knife
      include Knife::ClcBase

      banner 'knife clc server create (options)'

      option :clc_name,
        :long => '--name NAME',
        :description => 'Name of the server to create'

      option :clc_description,
        :long => '--description DESCRIPTION',
        :description => 'User-defined description of this server'

      option :clc_group,
        :long => '--group ID',
        :description => 'ID of the parent group'

      option :clc_source,
        :long => '--source ID',
        :description => 'ID of the server to use a source. May be the ID of a template, or when cloning, an existing server ID'

      option :clc_managed,
        :long => '--managed',
        :boolean => true,
        :description => 'Whether to create the server as managed or not'

      option :clc_managed_backup,
        :long => '--managed-backup',
        :boolean => true,
        :description => 'Whether to add managed backup to the server'

      option :clc_primary_dns,
        :long => '--primary-dns ADDRESS',
        :description => 'Primary DNS to set on the server'

      option :clc_secondary_dns,
        :long => '--secondary-dns ADDRESS',
        :description => 'Secondary DNS to set on the server'

      option :clc_network,
        :long => '--network ID',
        :description => 'ID of the network to which to deploy the server'

      option :clc_ip,
        :long => '--ip ADDRESS',
        :description => 'IP address to assign to the server'

      option :clc_password,
        :long => '--password PASSWORD',
        :description => 'Password of administrator or root user on server'

      option :clc_source_password,
        :long => '--source-password PASSWORD',
        :description => 'Password of the source server, used only when creating a clone from an existing server'

      option :clc_cpu,
        :long => '--cpu COUNT',
        :description => 'Number of processors to configure the server with'

      option :clc_cpu_autoscale_policy,
        :long => '--cpu-autoscale-policy ID',
        :description => 'ID of the vertical CPU Autoscale policy to associate the server with'

      option :clc_memory,
        :long => '--memory COUNT',
        :description => 'Number of GB of memory to configure the server with'

      option :clc_type,
        :long => '--type TYPE',
        :description => 'Whether to create a standard or hyperscale server'

      option :clc_storage_type,
        :long => '--storage-type TYPE',
        :description => 'For standard servers, whether to use standard or premium storage'

      option :clc_anti_affinity_policy,
        :long => '--anti-affinity-policy ID',
        :description => 'ID of the Anti-Affinity policy to associate the server with'

      option :clc_custom_fields,
        :long => '--custom-field KEY=VALUE',
        :description => 'Custom field key-value pair',
        :proc => ->(param) do
          @custom_fields ||= []
          @custom_fields << param
        end

      option :clc_disks,
        :long => '--disk PATH,SIZE,TYPE',
        :description => 'Configuration for an additional server disk',
        :proc => ->(param) do
          @disks ||= []
          @disks << param
        end

      option :clc_ttl,
        :long => '--ttl DATETIME',
        :description => 'Date/time that the server should be deleted'

      option :clc_packages,
        :long => '--package ID,KEY_1=VALUE,KEY_2=VALUE',
        :description => 'Package to run on the server after it has been built',
        :proc => ->(param) do
          @packages ||= []
          @packages << param
        end

      option :clc_configuration,
        :long => '--configuration ID',
        :description => 'Specifies the identifier for the specific configuration type of bare metal server to deploy'

      option :clc_os_type,
        :long => '--os-type TYPE',
        :description => 'Specifies the OS to provision with the bare metal server'

      option :clc_allowed_protocols,
        :long => '--allow PROTOCOL:FROM-TO',
        :description => 'Assigns public IP with permissions for specified protocol',
        :proc => ->(param) do
          @allowed_protocols ||= []
          @allowed_protocols << param
        end

      option :clc_wait,
        :long => '--wait',
        :description => 'Wait for operation completion',
        :boolean => true,
        :default => false

      attr_accessor :data

      def parse_and_validate_parameters
        unless config[:clc_name]
          errors << 'Name is required'
        end

        unless config[:clc_group]
          errors << 'Group ID is required'
        end

        unless config[:clc_source]
          errors << 'Source ID is required'
        end

        unless config[:clc_cpu]
          errors << 'Number of CPUs is required'
        end

        unless config[:clc_memory]
          errors << 'Number of memory GBs is required'
        end

        unless config[:clc_type]
          errors << 'Type is required'
        end

        config[:clc_custom_fields] && config[:clc_custom_fields].map! do |param|
          key, value = param.split('=', 2)
          { 'id' => key, 'value' => value }
        end

        config[:clc_disks] && config[:clc_disks].map! do |param|
          path, size, type = param.split(',', 3)
          { 'path' => path, 'sizeGB' => size, 'type' => type }
        end

        config[:clc_packages] && config[:clc_packages].map! do |param|
          id, package_params = param.split(',', 2)
          package_params = package_params.split(',').map { |pair| Hash[*pair.split('=', 2)] }
          { 'packageId' => id, 'parameters' => package_params }
        end

        config[:clc_allowed_protocols] && config[:clc_allowed_protocols].map! do |param|
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
              errors << 'No ports specified'
            else
              start_port, end_port = port_range.split('-')
              {
                'protocol' => protocol.downcase,
                'port' => start_port,
                'portTo' => end_port
              }.keep_if { |_, value| value }
            end
          else
            errors << 'Invalid protocol'
          end
        end && config[:clc_allowed_protocols].flatten!
      end

      def prepare_launch_params
        {
          'name' => config[:clc_name],
          'description' => config[:clc_description],
          'groupId' => config[:clc_group],
          'sourceServerId' => config[:clc_source],
          'isManagedOS' => config[:clc_managed],
          'isManagedBackup' => config[:clc_managed_backup],
          'primaryDns' => config[:clc_primary_dns],
          'secondaryDns' => config[:clc_secondary_dns],
          'networkId' => config[:clc_network],
          'ipAddress' => config[:clc_ip],
          'password' => config[:clc_password],
          'sourceServerPassword' => config[:clc_source_password],
          'cpu' => config[:clc_cpu],
          'cpuAutoscalePolicyId' => config[:clc_cpu_autoscale_policy],
          'memoryGB' => config[:clc_memory],
          'type' => config[:clc_type],
          'storageType' => config[:clc_storage_type],
          'antiAffinityPolicyId' => config[:clc_anti_affinity_policy],
          'customFields' => config[:clc_custom_fields],
          'additionalDisks' => config[:clc_disks],
          'ttl' => config[:clc_ttl],
          'packages' => config[:clc_packages],
        }.delete_if { |_, value| [nil, [], '', {}].include?(value) }
      end

      def execute
        ui.info 'Requesting server launch...'
        links = connection.create_server(prepare_launch_params)

        if config[:clc_wait]
          connection.wait_for(links['operation']) { putc '.' }
          ui.info "\n"
          ui.info "Server has been launched"
          self.data = connection.follow(links['resource'])
        else
          ui.info 'Launch request has been sent'
        end

        if config[:clc_allowed_protocols]
          ui.info 'Requesting public IP...'
          self.data ||= connection.follow(links['resource'])
          ip_links = connection.add_public_ip(data['id'], config[:clc_allowed_protocols])
          if config[:clc_wait]
            connection.wait_for(ip_links['operation']) { putc '.' }
            ui.info "\n"
            ui.info "Public IP has been assigned"
            self.data = connection.follow(links['resource'])
          else
            ui.info 'Public IP request has been sent'
          end
        end

        if config[:clc_wait]
          render_server
        else
          ui.info "You can check server status later with 'knife clc server show #{links['resource']['id']} --uuid'"
        end
      end

      def fields
        %w(id name description status groupId locationId osType type storageType)
      end

      def headers
        {
          'id' => 'ID',
          'name' => 'Name',
          'description' => 'Description',
          'status' => 'Status',
          'groupId' => 'Group',
          'locationId' => 'Location',
          'osType' => 'OS Type',
          'type' => 'Type',
          'storageType' => 'Storage Type'
        }
      end

      def render_server
        fields.each do |field|
          header = headers.fetch(field, field.capitalize)
          value = data.fetch(field, '-')

          if value
            puts ui.color(header, :bold) + ': ' + value.to_s
          end
        end
      end
    end
  end
end
