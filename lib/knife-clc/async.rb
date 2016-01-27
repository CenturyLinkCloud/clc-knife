require_relative 'async/config_options'

module Knife
  module Clc
    module Async
      def self.included(command_class)
        ConfigOptions.attach(command_class)
      end
    end
  end
end
