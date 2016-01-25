require_relative 'base/config_options'

require 'hirb'
require 'clc'
require 'knife-clc/version'

module Knife
  module Clc
    module Base
      def self.included(command_class)
        ConfigOptions.attach(command_class)
      end

      def connection
        @connection ||= ::Clc::Client.new(
          :username => config[:clc_username],
          :password => config[:clc_password],
          :endpoint => config[:clc_endpoint],
          :verbosity => config[:verbosity]
        )
      end

      def context
        @context ||= {}
      end

      def run
        $stdout.sync = true

        parse_and_validate_parameters

        if errors.any?
          show_errors
          show_usage
          exit 1
        else
          execute
        end
      end

      def parse_and_validate_parameters
      end

      def execute
      end

      def errors
        @errors ||= []
      end

      def show_errors
        errors.each { |message| ui.error message }
      end
    end
  end
end
