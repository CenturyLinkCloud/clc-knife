require_relative 'server_launch/config_options'
require_relative 'server_launch/server_launcher'

module Knife
  module Clc
    module ServerLaunch
      def self.included(command_class)
        ConfigOptions.attach(command_class)
      end

      def server_launcher
        @server_launcher ||= ServerLauncher.new(
          :config => config,
          :ui => ui,
          :connection => connection,
          :errors => errors
        )
      end
    end
  end
end
