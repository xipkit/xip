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

      attr_reader :options

      def initialize(options)
        super(options)

        @options = options
        @xiprc = parse_auth_file
        @port = @options['port']
        @host = @options['host']
        CLI::UI::StdoutRouter.enable

        # TODO: Handle scenario where a host is specified via -h

        if @xiprc.size == 0
          @host = @key = nil
          puts CLI::UI.fmt("{{yellow:No hosts registered. Generating a temporary host.}}")
          puts CLI::UI.fmt("{{yellow:You can register a permanent host with {{command:`xip register`}}")
        elsif @xiprc.size == 1
          # Only a single host has been registered, load it
          @host = @xiprc.first['host']
          @key = @xiprc.first['key']
        elsif @xiprc.size > 1
          @host = @xiprc.first['host']
          @key = @xiprc.first['key']
          puts CLI::UI.fmt("{{yellow:Multiple hosts registered. Defaulting to `#{@host}`}}")
          puts CLI::UI.fmt("{{yellow:You can specify a host with {{command:-h}}")
        end

        puts ""
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
