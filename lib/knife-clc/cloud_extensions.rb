require_relative 'cloud_extensions/cloud_adapter'

module Knife
  module Clc
    module CloudExtensions
      def cloud_adapter
        @cloud_adapter ||= CloudAdapter.new(:connection => connection)
      end
    end
  end
end
