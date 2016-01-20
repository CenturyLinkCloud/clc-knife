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
          :connection => connection,
          :config => config,
          :errors => errors,
          :ui => ui
        )
      end
    end
  end
end
