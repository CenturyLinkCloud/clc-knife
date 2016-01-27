module Knife
  module Clc
    module IpAssignment
      class Mapper
        attr_reader :config

        def initialize(params)
          @config = params.fetch(:config)
        end

        def prepare_ip_params
          {
            'ports' => config[:clc_allowed_protocols],
            'sourceRestrictions' => config[:clc_sources]
          }.delete_if { |_, value| value.nil? || value.empty? }
        end
      end
    end
  end
end
