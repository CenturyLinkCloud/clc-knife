require 'knife-clc/version'
require 'hirb'
require 'clc'

class Chef
  class Knife
    module ClcBase
      def self.included(klass)
        klass.class_eval do
          option :clc_username,
            :long => '--username NAME',
            :description => 'Name of the user to access CLC API',
            :on => :head

          option :clc_password,
            :long => '--password PASSWORD',
            :description => 'Password for CLC user account',
            :on => :head

          option :clc_endpoint,
            :long => '--endpoint URL',
            :description => 'Alternative CLC API URL',
            :on => :head

          def connection
            @connection ||= ::Clc::Client.new(
              :username => config[:clc_username],
              :password => config[:clc_password],
              :endpoint => config[:clc_endpoint],
              :verbosity => config[:verbosity]
            )
          end

          attr_writer :context

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
  end
end
