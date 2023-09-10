# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

require 'bunny'

ENV['OTEL_TRACES_EXPORTER'] = 'console'
OpenTelemetry::SDK.configure do |c|
  c.use 'OpenTelemetry::Instrumentation::Bunny'
end

# Start a communication session with RabbitMQ
conn = Bunny.new
conn.start

# Open a channel
ch = conn.create_channel

# Declare a queue
q  = ch.queue('opentelemetry-ruby-demonstration')

# Publish a message to the default exchange which then gets routed to the demostration queue
q.publish('Hello, opentelemetry!')

# Fetch a message from the queue
q.pop do |delivery_info, metadata, payload|
  puts "Message: #{payload}"
  puts "Delivery info: #{delivery_info}"
  puts "Metadata: #{metadata}"
end

# Close the connection
conn.stop

# Wait for all traces to be exported (if there's any pending)
OpenTelemetry.tracer_provider.shutdown
