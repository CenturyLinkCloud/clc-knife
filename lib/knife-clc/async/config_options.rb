module Knife
  module Clc
    module Async
      class ConfigOptions
        def self.attach(command_class)
          command_class.class_eval do
            option :clc_wait,
              :long => '--wait',
              :description => 'Wait for operation completion',
              :boolean => true,
              :default => false,
              :on => :head
          end
        end
      end
    end
  end
end
