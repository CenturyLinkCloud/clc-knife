require 'chef/knife/bootstrap'
require 'chef/knife/bootstrap_windows_winrm'

module Knife
  module Clc
    module Bootstrap
      class ConfigOptions
        def self.attach(command_class)
          command_class.class_eval do
            option :clc_bootstrap,
              :long => '--bootstrap',
              :description => '[Bootstrap] Bootstrap launched server',
              :boolean => true,
              :default => false,
              :on => :head

            option :clc_bootstrap_private,
              :long => '--bootstrap-private',
              :description => '[Bootstrap] Bootstrap from private network. Requires client or SSH gateway to have an access to private network of the server',
              :boolean => true,
              :default => false,
              :on => :head

            option :clc_bootstrap_platform,
              :long => '--bootstrap-platform PLATFORM',
              :description => '[Bootstrap] Sets bootstrapping server platform as windows or linux. Derived automatically by default',
              :on => :head
          end

          attach_platform_specific_options(command_class)
        end

        # TODO AS: Once bootstrapper has separate platform modules - rework this
        def self.attach_platform_specific_options(command_class)
          linux_options = Chef::Knife::Bootstrap.options.dup
          windows_options = Chef::Knife::BootstrapWindowsWinrm.options.dup

          windows_specific_option_keys = windows_options.keys - linux_options.keys
          linux_specific_option_keys = linux_options.keys - windows_options.keys

          linux_specific_option_keys.each do |linux_key|
            description = linux_options[linux_key][:description]
            linux_options[linux_key][:description] = '[Linux Only] ' + description
          end

          windows_specific_option_keys.each do |windows_key|
            description = windows_options[windows_key][:description]
            windows_options[windows_key][:description] = '(Windows Only) ' + description
          end

          windows_options.each do |name, settings|
            settings[:description] = '[Bootstrap] ' + settings[:description]
          end

          linux_options.each do |name, settings|
            settings[:description] = '[Bootstrap] ' + settings[:description]
          end

          command_class.options
            .merge!(linux_options)
            .merge!(windows_options)
        end
      end
    end
  end
end
