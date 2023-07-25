# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

module OpenTelemetry
  module Instrumentation
    module Bunny
      # The PatchHelper module provides functionality shared between patches.
      #
      # For additional details around trace messaging semantics
      # See https://github.com/open-telemetry/opentelemetry-specification/blob/master/specification/trace/semantic_conventions/messaging.md#messaging-attributes
      module PatchHelpers
        def self.with_publish_span(channel, tracer, exchange, routing_key, &block)
          attributes = basic_attributes(channel, channel.connection, exchange, routing_key)
          destination = destination_name(exchange, routing_key)

          tracer.in_span("publish #{destination}", attributes: attributes, kind: :producer, &block)
        end

        def self.inject_context_into_property(properties, key)
          properties[key] ||= {}
          OpenTelemetry.propagation.inject(properties[key])
        end

        def self.basic_attributes(channel, transport, exchange, routing_key)
          attributes = {
            'messaging.system' => 'rabbitmq',
            'messaging.destination' => exchange,
            'messaging.destination_kind' => destination_kind(channel, exchange),
            'messaging.protocol' => 'AMQP',
            'messaging.protocol_version' => ::Bunny.protocol_version,
            'net.peer.name' => transport.host,
            'net.peer.port' => transport.port
          }
          attributes['messaging.rabbitmq.routing_key'] = routing_key if routing_key
          attributes
        end

        def self.destination_name(exchange, routing_key)
          [exchange, routing_key].compact.join('.')
        end

        def self.destination_kind(channel, exchange)
          # The default exchange with no name is always a direct exchange
          # https://github.com/ruby-amqp/bunny/blob/master/lib/bunny/exchange.rb#L33
          return 'queue' if exchange == ''

          # All exchange types https://www.rabbitmq.com/tutorials/amqp-concepts.html#exchanges
          # except direct exchanges are mapped to topic
          return 'queue' if channel.find_exchange(exchange)&.type == :direct

          'topic'
        end
      end
    end
  end
end
