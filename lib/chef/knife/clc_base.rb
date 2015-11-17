require 'knife-clc/version'
require 'formatador'
require 'clc/client'

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
