module Knife
  module Clc
    module IpAssignment
      class ConfigOptions
        def self.attach(command_class)
          command_class.class_eval do
            option :clc_allowed_protocols,
              :long => '--allow PROTOCOL:FROM[-TO]',
              :description => 'Assigns public IP with permissions for specified protocol',
              :on => :head,
              :proc => ->(param) do
                Chef::Config[:knife][:clc_allowed_protocols] ||= []
                Chef::Config[:knife][:clc_allowed_protocols] << param
              end

            option :clc_sources,
              :long => '--source CIDR',
              :description => 'The source IP address range allowed to access the new public IP address',
              :on => :head,
              :proc => ->(param) do
                Chef::Config[:knife][:clc_sources] ||= []
                Chef::Config[:knife][:clc_sources] << param
              end
          end
        end
      end
    end
  end
end
