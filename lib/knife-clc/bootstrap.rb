require_relative 'bootstrap/config_options'
require_relative 'bootstrap/bootstrapper'

module Knife
  module Clc
    module Bootstrap
      def self.included(command_class)
        ConfigOptions.attach(command_class)
      end

      def bootstrapper
        @bootstrapper = Bootstrapper.new(
          :cloud_adapter => cloud_adapter,
          :config => config,
          :errors => errors
        )
      end
    end
  end
end
