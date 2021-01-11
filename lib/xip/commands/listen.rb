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

      LISTEN_URI = 'ws://0.0.0.0:3000/listen'

      attr_reader :options

      def initialize(options)
        super(options)

        @options = options
      end

      def start
        EM.run do

          ws = WebSocket::EventMachine::Client.connect(uri: LISTEN_URI)

          Signal.trap('INT') {
            ws.close
            exit
          }

          Signal.trap('TERM') {
            ws.close
            exit
          }

          ws.onopen do
            puts "Connected"
          end

          ws.onping do
            puts "Got ping."
            ws.pong
          end

          ws.onmessage do |msg, type|
            puts "Received message: #{msg}"
          end

          ws.onclose do |code, reason|
            puts "Disconnected."
            exit
          end

        end
      end

    end
  end
end
