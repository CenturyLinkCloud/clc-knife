module Knife
  module Clc
    module Bootstrap
      class SubcommandLoader
        def load(params)
          klass = params.fetch(:class)
          config = params.fetch(:config)

          klass.load_deps
          command = klass.new
          command.config.merge!(config)
          command.configure_chef
          command
        end
      end
    end
  end
end
