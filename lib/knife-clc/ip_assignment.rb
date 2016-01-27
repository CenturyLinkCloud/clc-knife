require_relative 'ip_assignment/config_options'
require_relative 'ip_assignment/ip_assigner'

module Knife
  module Clc
    module IpAssignment
      def self.included(command_class)
        ConfigOptions.attach(command_class)
      end

      def ip_assigner
        @ip_assigner ||= IpAssigner.new(
          :connection => connection,
          :config => config,
          :errors => errors
        )
      end
    end
  end
end
