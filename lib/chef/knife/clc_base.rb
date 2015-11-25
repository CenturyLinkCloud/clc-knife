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
            @connection ||= ::Clc::Client.new
          end
        end
      end
    end
  end
end
