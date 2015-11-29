require 'knife-clc/version'
require 'formatador'
require 'hirb'
require 'clc'

class Chef
  class Knife
    module ClcBase
      def self.included(klass)
        klass.class_eval do
          def connection
            @connection ||= ::Clc::Client.new(:verbosity => Chef::Config[:verbosity])
          end

          def run
            $stdout.sync = true
            parse_and_validate_parameters
            check_for_errors!
            execute
          end

          def parse_and_validate_parameters
          end

          def execute
          end

          def errors
            @errors ||= []
          end

          def check_for_errors!
            unless errors.empty?
              errors.each { |message| ui.error message }
              show_usage
              exit 1
            end
          end
        end
      end
    end
  end
end
