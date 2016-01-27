module Knife
  module Clc
    module ServerLaunch
      class Mapper
        attr_reader :config

        def initialize(params)
          @config = params.fetch(:config)
        end

        def prepare_launch_parameters
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
      end
    end
  end
end
