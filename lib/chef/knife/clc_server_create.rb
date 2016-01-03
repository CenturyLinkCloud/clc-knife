require 'chef/knife/clc_base'
require 'chef/knife/clc_server_show'
require 'chef/knife/bootstrap'

class Chef
  class Knife
    class ClcServerCreate < Knife
      include Knife::ClcBase

      banner 'knife clc server create (options)'

      option :clc_name,
        :long => '--name NAME',
        :description => 'Name of the server to create',
        :on => :head

      option :clc_description,
        :long => '--description DESCRIPTION',
        :description => 'User-defined description of this server',
        :on => :head

      option :clc_group,
        :long => '--group ID',
        :description => 'ID of the parent group',
        :on => :head

      option :clc_source_server,
        :long => '--source-server ID',
        :description => 'ID of the server to use a source. May be the ID of a template, or when cloning, an existing server ID',
        :on => :head

      option :clc_managed,
        :long => '--managed',
        :boolean => true,
        :description => 'Whether to create the server as managed or not',
        :on => :head

      option :clc_managed_backup,
        :long => '--managed-backup',
        :boolean => true,
        :description => 'Whether to add managed backup to the server',
        :on => :head

      option :clc_primary_dns,
        :long => '--primary-dns ADDRESS',
        :description => 'Primary DNS to set on the server',
        :on => :head

      option :clc_secondary_dns,
        :long => '--secondary-dns ADDRESS',
        :description => 'Secondary DNS to set on the server',
        :on => :head

      option :clc_network,
        :long => '--network ID',
        :description => 'ID of the network to which to deploy the server',
        :on => :head

      option :clc_ip,
        :long => '--ip ADDRESS',
        :description => 'IP address to assign to the server',
        :on => :head

      option :clc_server_password,
        :long => '--server-password PASSWORD',
        :description => 'Password of administrator or root user on server',
        :on => :head

      option :clc_source_server_password,
        :long => '--source-server-password PASSWORD',
        :description => 'Password of the source server, used only when creating a clone from an existing server',
        :on => :head

      option :clc_cpu,
        :long => '--cpu COUNT',
        :description => 'Number of processors to configure the server with',
        :on => :head

      option :clc_cpu_autoscale_policy,
        :long => '--cpu-autoscale-policy ID',
        :description => 'ID of the vertical CPU Autoscale policy to associate the server with',
        :on => :head

      option :clc_memory,
        :long => '--memory COUNT',
        :description => 'Number of GB of memory to configure the server with',
        :on => :head

      option :clc_type,
        :long => '--type TYPE',
        :description => 'Whether to create a standard or hyperscale server',
        :on => :head

      option :clc_storage_type,
        :long => '--storage-type TYPE',
        :description => 'For standard servers, whether to use standard or premium storage',
        :on => :head

      option :clc_anti_affinity_policy,
        :long => '--anti-affinity-policy ID',
        :description => 'ID of the Anti-Affinity policy to associate the server with',
        :on => :head

      option :clc_custom_fields,
        :long => '--custom-field KEY=VALUE',
        :description => 'Custom field key-value pair',
        :on => :head,
        :proc => ->(param) do
          Chef::Config[:knife][:clc_custom_fields] ||= []
          Chef::Config[:knife][:clc_custom_fields] << param
        end

      option :clc_disks,
        :long => '--disk PATH,SIZE,TYPE',
        :description => 'Configuration for an additional server disk',
        :on => :head,
        :proc => ->(param) do
          Chef::Config[:knife][:clc_disks] ||= []
          Chef::Config[:knife][:clc_disks] << param
        end

      option :clc_ttl,
        :long => '--ttl DATETIME',
        :description => 'Date/time that the server should be deleted',
        :on => :head

      option :clc_packages,
        :long => '--package ID,KEY_1=VALUE[,KEY_2=VALUE]',
        :description => 'Package to run on the server after it has been built',
        :on => :head,
        :proc => ->(param) do
          Chef::Config[:knife][:clc_packages] ||= []
          Chef::Config[:knife][:clc_packages] << param
        end

      option :clc_configuration,
        :long => '--configuration ID',
        :description => 'Specifies the identifier for the specific configuration type of bare metal server to deploy',
        :on => :head

      option :clc_os_type,
        :long => '--os-type TYPE',
        :description => 'Specifies the OS to provision with the bare metal server',
        :on => :head

      option :clc_allowed_protocols,
        :long => '--allow PROTOCOL:FROM[-TO]',
        :description => 'Assigns public IP with permissions for specified protocol',
        :on => :head,
        :proc => ->(param) do
          Chef::Config[:knife][:clc_allowed_protocols] ||= []
          Chef::Config[:knife][:clc_allowed_protocols] << param
        end

      option :clc_sources,
        :long => '--source CIDR',
        :description => 'The source IP address range allowed to access the new public IP address',
        :on => :head,
        :proc => ->(param) do
          Chef::Config[:knife][:clc_sources] ||= []
          Chef::Config[:knife][:clc_sources] << param
        end

      option :clc_wait,
        :long => '--wait',
        :description => 'Wait for operation completion',
        :boolean => true,
        :default => false,
        :on => :head

      option :clc_bootstrap,
        :long => '--bootstrap',
        :description => 'Bootstrap launched server using standard `knife bootstrap` command',
        :boolean => true,
        :default => false,
        :on => :head

      def parse_and_validate_parameters
        unless config[:clc_name]
          errors << 'Name is required'
        end

        unless config[:clc_group]
          errors << 'Group ID is required'
        end

        unless config[:clc_source_server]
          errors << 'Source server ID is required'
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

        custom_fields = config[:clc_custom_fields]
        if custom_fields && custom_fields.any?
          parse_custom_fields(custom_fields)
        end

        disks = config[:clc_disks]
        if disks && disks.any?
          parse_disks(disks)
        end

        packages = config[:clc_packages]
        if packages && packages.any?
          parse_packages(packages)
        end

        permissions = config[:clc_allowed_protocols]
        if permissions && permissions.any?
          parse_protocol_permissions(permissions)
        end

        sources = config[:clc_sources]
        if sources && sources.any?
          parse_sources(sources)
        end

        bootstrap = config[:clc_bootstrap]
        if bootstrap
          # Checking Chef connectivity
          Chef::Node.list
        end
      end

      def parse_custom_fields(custom_fields)
        custom_fields.map! do |param|
          key, value = param.split('=', 2)

          unless key && value
            errors << "Custom field definition #{param} is malformed"
            next
          end

          { 'id' => key, 'value' => value }
        end
      end

      def parse_disks(disks)
        disks.map! do |param|
          path, size, type = param.split(',', 3)

          unless path && size && type
            errors << "Disk definition #{param} is malformed"
          end

          { 'path' => path, 'sizeGB' => size, 'type' => type }
        end
      end

      def parse_packages(packages)
        packages.map! do |param|
          begin
            id, package_params = param.split(',', 2)
            package_params = package_params.split(',').map { |pair| Hash[*pair.split('=', 2)] }
            { 'packageId' => id, 'parameters' => package_params }
          rescue Exception => e
            errors << "Package definition #{param} is malformed"
          end
        end
      end

      def parse_protocol_permissions(permissions)
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

      def parse_sources(sources)
        sources.map! do |cidr|
          { 'cidr' => cidr }
        end
      end

      def prepare_launch_params
        {
          'name' => config[:clc_name],
          'description' => config[:clc_description],
          'groupId' => config[:clc_group],
          'sourceServerId' => config[:clc_source_server],
          'isManagedOS' => config[:clc_managed],
          'isManagedBackup' => config[:clc_managed_backup],
          'primaryDns' => config[:clc_primary_dns],
          'secondaryDns' => config[:clc_secondary_dns],
          'networkId' => config[:clc_network],
          'ipAddress' => config[:clc_ip],
          'password' => config[:clc_server_password],
          'sourceServerPassword' => config[:clc_source_server_password],
          'cpu' => config[:clc_cpu].to_i,
          'cpuAutoscalePolicyId' => config[:clc_cpu_autoscale_policy],
          'memoryGB' => config[:clc_memory].to_i,
          'type' => config[:clc_type],
          'storageType' => config[:clc_storage_type],
          'antiAffinityPolicyId' => config[:clc_anti_affinity_policy],
          'customFields' => config[:clc_custom_fields],
          'additionalDisks' => config[:clc_disks],
          'ttl' => config[:clc_ttl],
          'packages' => config[:clc_packages],
        }.delete_if { |_, value| !value.kind_of?(Integer) && (value.nil? || value.empty?) }
      end

      def prepare_ip_params
        {
          'ports' => config[:clc_allowed_protocols],
          'sourceRestrictions' => config[:clc_sources]
        }.delete_if { |_, value| value.nil? || value.empty? }
      end

      def execute
        config[:clc_wait] ? sync_create_server : async_create_server
      end

      def sync_create_server
        ui.info 'Requesting server launch...'
        links = connection.create_server(prepare_launch_params)
        connection.wait_for(links['operation']['id']) { putc '.' }
        ui.info "\n"
        ui.info "Server has been launched"

        if config[:clc_allowed_protocols]
          ui.info 'Requesting public IP...'
          server = connection.follow(links['resource'])
          ip_links = connection.create_ip_address(server['id'], prepare_ip_params)
          connection.wait_for(ip_links['operation']['id']) { putc '.' }
          ui.info "\n"
          ui.info 'Public IP has been assigned'
        end

        if config[:clc_bootstrap]
          sync_bootstrap(links['resource']['id'])
        end

        argv = [links['resource']['id'], '--uuid', '--creds']
        if config[:clc_allowed_protocols]
          argv << '--ports'
        end

        if (username = config[:clc_username]) && (password = config[:clc_password])
          argv.concat(['--username', username, '--password', password])
        end

        Chef::Knife::ClcServerShow.new(argv).run
      end

      def async_create_server
        launch_params = prepare_launch_params

        if config[:clc_bootstrap]
          ui.info 'Bootstrap has been scheduled'
          add_bootstrapping_params(launch_params)
        end

        ui.info 'Requesting server launch...'
        links = connection.create_server(launch_params)
        ui.info 'Launch request has been sent'
        ui.info "You can check launch operation status with 'knife clc operation show #{links['operation']['id']}'"

        if config[:clc_allowed_protocols]
          ui.info 'Requesting public IP...'
          server = connection.follow(links['resource'])
          ip_links = connection.create_ip_address(server['id'], prepare_ip_params)
          ui.info 'Public IP request has been sent'
          ui.info "You can check assignment operation status with 'knife clc operation show #{ip_links['operation']['id']}'"
        end

        argv = [links['resource']['id'], '--uuid', '--creds']
        argv << '--ports' if config[:clc_allowed_protocols]

        ui.info "You can check server status later with 'knife clc server show #{argv.join(' ')}'"
      end

      def sync_bootstrap(uuid)
        server = connection.show_server(uuid, true)

        command = bootstrap_command

        command.name_args = [get_server_fqdn(server)]

        username, password = config.values_at(:ssh_user, :ssh_password)
        unless username && password
          creds = get_server_credentials(server)
          command.config.merge!(:ssh_user => creds['userName'], :ssh_password => creds['password'])
        end

        tries = 2
        begin
          command.run
        rescue Errno::ETIMEDOUT => e
          tries -= 1

          if tries > 0
            ui.info 'Retrying host connection...'
            retry
          else
            raise
          end
        end
      end

      def add_bootstrapping_params(launch_params)
        launch_params['packages'] ||= []
        launch_params['packages'] << package_for_async_bootstrap
      end

      def package_for_async_bootstrap
        {
          'packageId' => 'a5d9d04369df4276a4f98f2ca7f7872b',
          'parameters' => {
            'Mode' => 'Ssh',
            'Script' => bootstrap_command.render_template
          }
        }
      end

      def get_server_fqdn(server)
        public_ips = server['details']['ipAddresses'].map { |addr| addr['public'] }.compact
        public_ip = public_ips.first

        private_ips = server['details']['ipAddresses'].map { |addr| addr['internal'] }.compact
        private_ip = private_ips.first

        public_ip || private_ip
      end

      def get_server_credentials(server)
        creds_link = server['links'].find { |link| link['rel'] == 'credentials' }
        connection.follow(creds_link) if creds_link
      end

      def self.bootstrap_command_class
        Chef::Knife::Bootstrap
      end

      def bootstrap_command
        command_class = self.class.bootstrap_command_class
        command_class.load_deps
        command = command_class.new
        command.config.merge!(config)
        command.configure_chef
        command
      end

      self.options.merge!(bootstrap_command_class.options)
    end
  end
end
