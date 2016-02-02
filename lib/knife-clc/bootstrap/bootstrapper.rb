require_relative 'validator'
require_relative 'connectivity_helper'

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

        # Sync, Windows... (before the launch...#?)
        def enable_winrm_package
          {
            'packageId' => 'a5d9d04369df4276a4f98f2ca7f7872b',
            'parameters' => {
              'Mode' => 'PowerShell',
              'Script' => "
                winrm set winrm/config/service/auth '@{Basic=\"true\"}'
                winrm set winrm/config/service '@{AllowUnencrypted=\"true\"}'
              "
            }
          }
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

        def sync_bootstrap_method
          case config[:clc_bootstrap_platform]
          when 'linux' then Methods::SyncLinuxSsh.new(:cloud_adapter => cloud_adapter, :config => config, :connectivity_helper => connectivity_helper)
          when 'windows' then Methods::SyncWindowsWinrm.new(:cloud_adapter => cloud_adapter, :config => config, :connectivity_helper => connectivity_helper)
          end
        end

        def async_bootstrap_method
          case config[:clc_bootstrap_platform]
          when 'linux' then Methods::AsyncLinuxPackage.new(:config => config)
          when 'windows' then Methods::AsyncWindowsPackage.new(:config => config)
          end
        end
      end
    end
  end
end
