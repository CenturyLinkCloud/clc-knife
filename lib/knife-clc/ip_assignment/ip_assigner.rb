require_relative 'validator'
require_relative 'mapper'

module Knife
  module Clc
    module IpAssignment
      class IpAssigner
        attr_reader :connection, :config, :errors

        def initialize(params)
          @connection = params.fetch(:connection)
          @config = params.fetch(:config)
          @errors = params.fetch(:errors)
        end

        # TODO: Params ordering dependency
        def execute(server_id)
          connection.create_ip_address(server_id, ip_params)
        end

        def prepare
          validator.validate
        end

        private

        def ip_params
          mapper.prepare_ip_params
        end

        def validator
          @validator ||= Validator.new(:config => config, :errors => errors)
        end

        def mapper
          @mapper ||= Mapper.new(:config => config, :errors => errors)
        end
      end
    end
  end
end
