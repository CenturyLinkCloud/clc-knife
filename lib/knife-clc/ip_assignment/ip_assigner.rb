require 'knife-clc/mixins/ip_assignment/validator'
require 'knife-clc/mixins/ip_assignment/mapper'

require_relative 'validator'
require_relative 'mapper'

module Knife
  module Clc
    module IpAssignment
      class IpAssigner
        extend Forwardable

        def_delegator :validator, :validate

        attr_reader :connection, :config, :errors

        def initialize(params)
          @connection = params.fetch(:connection)
          @config = params.fetch(:config)
          @errors = params.fetch(:errors)
        end

        # TODO AS: PARAMS, DANGER!
        def execute(server_id)
          connection.create_ip_address(server_id, ip_params)
        end

        private

        def ip_params
          mapper.prepare
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
