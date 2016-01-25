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
          server_params = launch_parameters
          yield server_params if block_given?

          connection.create_server(server_params)
        end

        def prepare
          validator.validate
        end

        private

        def launch_parameters
          mapper.prepare_launch_parameters
        end

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
