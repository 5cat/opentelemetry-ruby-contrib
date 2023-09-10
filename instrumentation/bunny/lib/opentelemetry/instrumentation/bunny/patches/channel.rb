# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Bunny
      module Patches
        # The Channel module contains the instrumentation patch for Channel#basic_publish
        module Channel
          def basic_publish(payload, exchange, routing_key, opts = {})
            OpenTelemetry::Instrumentation::Bunny::PatchHelpers.with_publish_span(self, tracer, exchange, routing_key) do
              OpenTelemetry::Instrumentation::Bunny::PatchHelpers.inject_context_into_property(opts, :headers)

              super(payload, exchange, routing_key, opts)
            end
          end

          private

          def tracer
            Bunny::Instrumentation.instance.tracer
          end
        end
      end
    end
  end
end
