module Knife
  module Clc
    module ServerLaunch
      class ConfigOptions
        def self.attach(command_class)
          command_class.class_eval do
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
          end
        end
      end
    end
  end
end
