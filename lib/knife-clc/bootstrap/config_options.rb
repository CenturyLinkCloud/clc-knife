require 'chef/knife/bootstrap'

module Knife
  module Clc
    module Bootstrap
      class ConfigOptions
        def self.attach(command_class)
          command_class.class_eval do
            option :clc_bootstrap,
              :long => '--bootstrap',
              :description => 'Bootstrap launched server using standard `knife bootstrap` command',
              :boolean => true,
              :default => false,
              :on => :head

            option :clc_bootstrap_private,
              :long => '--bootstrap-private',
              :description => 'Bootstrap from private network. Requires client or SSH gateway to have an access to private network of the server',
              :boolean => true,
              :default => false,
              :on => :head

            option :clc_bootstrap_platform,
              :long => '--bootstrap-platform PLATFORM',
              :description => 'Assume bootstrapping server platform as windows or linux. Derived automatically by default',
              :on => :head
          end

          attach_platform_specific_options(command_class)
        end

        # TODO AS: Windows options will be generated here too
        def self.attach_platform_specific_options(command_class)
          command_class.options.merge!(Chef::Knife::Bootstrap.options)
        end
      end
    end
  end
end
