# frozen_string_literal: true

# Copyright The OpenTelemetry Authors
#
# SPDX-License-Identifier: Apache-2.0

require 'rubygems'
require 'bundler/setup'

Bundler.require

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

# Needed to wait for the message before exiting
mutex = Mutex.new
event_received = ConditionVariable.new

# Process messages asynchronously with the following block
q.subscribe do |delivery_info, properties, payload|
  mutex.synchronize do
    puts "Message: #{payload}"
    puts "Delivery info: #{delivery_info}"
    puts "Metadata: #{properties}"

    event_received.signal
  end
end

# Publish a message to the default exchange which then gets routed to the demostration queue
# and wait for the message to be processed asynchronously
mutex.synchronize do
  q.publish('Hello, opentelemetry!')
  event_received.wait(mutex)
end

# Close the connection
conn.stop

# Wait for all traces to be exported (if there's any pending)
OpenTelemetry.tracer_provider.shutdown
