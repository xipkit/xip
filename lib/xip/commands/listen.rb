# frozen_string_literal: true

require 'xip/commands/command'
require 'websocket-eventmachine-client'

module Xip
  module Commands
    # Introspectable tunnel to listen for message service webhooks.
    #
    # It is run with:
    #
    #   `bundle exec xip listen`
    class Listen < Command

      LISTEN_URI = 'wss://ws-mt1.pusher.com/app/892bee062bc081dc397c'

      attr_reader :options

      def initialize(options)
        super(options)

        @options = options
      end

      def start
        EM.run do

          ws = WebSocket::EventMachine::Client.connect(uri: LISTEN_URI)

          ws.onopen do
            puts "Connected"
          end

          ws.onping do
            ws.pong
          end

          ws.onmessage do |msg, type|
            puts "Received message: #{msg}"
          end

          ws.onclose do |code, reason|
            puts "Disconnected with status code: #{code}"
          end

        end
      end

    end
  end
end
