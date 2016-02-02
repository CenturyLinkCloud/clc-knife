require_relative 'validator'
require_relative 'mapper'

module Knife
  module Clc
    module ServerLaunch
      class ServerLauncher
        attr_reader :config, :connection, :errors

        def initialize(params)
          @config = params.fetch(:config)
          @connection = params.fetch(:connection)
          @errors = params.fetch(:errors)
        end

        def execute
          connection.create_server(launch_parameters)
        end

        def prepare
          validator.validate
        end

        def launch_parameters
          @launch_parameters ||= mapper.prepare_launch_parameters
        end

        private

        def validator
          @validator ||= Validator.new(:config => config, :errors => errors)
        end

        def mapper
          @mapper ||= Mapper.new(:config => config)
        end
      end
    end
  end
end
