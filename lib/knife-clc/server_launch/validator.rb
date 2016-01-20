module Knife
  module Clc
    module ServerLaunch
      class Validator
        attr_reader :config, :errors

        def initialize(params)
          @config = params.fetch(:config)
          @errors = params.fetch(:errors)
        end

        def validate
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
        end

        private

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
      end
    end
  end
end
