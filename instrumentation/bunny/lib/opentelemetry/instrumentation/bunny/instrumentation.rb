# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'opentelemetry-instrumentation-base'

module OpenTelemetry
  module Instrumentation
    module Bunny
      # The Instrumentation class contains logic to detect and install the
      # bunny instrumentation
      class Instrumentation < OpenTelemetry::Instrumentation::Base
        install do |_config|
          require_patches
          patch
        end

        present do
          defined?(::Bunny)
        end

        option :extend_producer_trace, default: false, validate: :boolean

        private

        def require_patches
          require_relative 'patch_helpers'
          require_relative 'patches/channel'
          require_relative 'patches/consumer'
        end

        def patch
          ::Bunny::Channel.prepend(Patches::Channel)
          ::Bunny::Consumer.prepend(Patches::Consumer)
        end
      end
    end
  end
end
