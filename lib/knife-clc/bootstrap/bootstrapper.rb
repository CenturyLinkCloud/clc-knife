require_relative 'validator'
require_relative 'connectivity_helper'
require_relative 'subcommand_loader'

require_relative 'methods/async_linux_package'
require_relative 'methods/async_windows_package'
require_relative 'methods/sync_linux_ssh'
require_relative 'methods/sync_windows_winrm'

module Knife
  module Clc
    module Bootstrap
      class Bootstrapper
        attr_reader :cloud_adapter, :config, :errors

        def initialize(params)
          @cloud_adapter = params.fetch(:cloud_adapter)
          @config = params.fetch(:config)
          @errors = params.fetch(:errors)
        end

        def sync_bootstrap(server)
          sync_bootstrap_method.execute(server)
        end

        def async_bootstrap(launch_parameters)
          async_bootstrap_method.execute(launch_parameters)
        end

        def prepare
          validator.validate
        end

        private

        def validator
          @validator ||= Validator.new(
            :connection => cloud_adapter.connection,
            :config => config,
            :errors => errors
          )
        end

        def connectivity_helper
          @connectivity_helper ||= ConnectivityHelper.new
        end

        def subcommand_loader
          @subcommand_loader ||= SubcommandLoader.new
        end

        def sync_bootstrap_method
          case config[:clc_bootstrap_platform]
          when 'linux'
            Methods::SyncLinuxSsh.new(
              :cloud_adapter => cloud_adapter,
              :config => config,
              :connectivity_helper => connectivity_helper,
              :subcommand_loader => subcommand_loader
            )
          when 'windows'
            Methods::SyncWindowsWinrm.new(
              :cloud_adapter => cloud_adapter,
              :config => config,
              :connectivity_helper => connectivity_helper,
              :subcommand_loader => subcommand_loader
            )
          else
            raise 'No suitable bootstrap method found'
          end
        end

        def async_bootstrap_method
          case config[:clc_bootstrap_platform]
          when 'linux'
            Methods::AsyncLinuxPackage.new(
              :config => config,
              :subcommand_loader => subcommand_loader
            )
          when 'windows'
            Methods::AsyncWindowsPackage.new(
              :config => config,
              :subcommand_loader => subcommand_loader
            )
          else
            raise 'No suitable bootstrap method found'
          end
        end
      end
    end
  end
end
