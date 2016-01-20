module Knife
  module Clc
    module Base
      class ConfigOptions
        def self.attach(command_class)
          command_class.class_eval do
            option :clc_username,
              :long => '--username NAME',
              :description => 'Name of the user to access CLC API',
              :on => :head

            option :clc_password,
              :long => '--password PASSWORD',
              :description => 'Password for CLC user account',
              :on => :head

            option :clc_endpoint,
              :long => '--endpoint URL',
              :description => 'Alternative CLC API URL',
              :on => :head
          end
        end
      end
    end
  end
end
