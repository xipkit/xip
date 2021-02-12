# frozen_string_literal: true

require 'xip/commands/command'
require 'websocket-eventmachine-client'
require 'http'
require 'yaml'
require 'base64'

module Xip
  module Commands
    # Introspectable tunnel to listen for message service webhooks.
    #
    # It is run with:
    #
    #   `bundle exec xip listen`
    class Listen < Command

      LISTEN_CMD   = "LISTEN"
      WEBHOOK_CMD  = "WEBHOOK"
      SUCCESS_CMD  = "SUCCESS"
      ERR_CMD      = "ERR"

      attr_reader :options, :host, :port, :key

      def initialize(options)
        super(options)

        @xiprc  = load_xiprc
        @port   = options['port']
        @host   = options['host']

        # TODO: Handle scenario where a host is specified via -h
        if @host.present?
          rc_entry = @xiprc.find { |rc_entry| rc_entry['host'] == @host }

          unless rc_entry.present?
            cmd_puts("{{red:No entry found in .xiprc for host}} {{command:#{@host}}}{{red:. Have you registered it yet? See:}} {{command:`xip register --help`}}")
            exit(1)
          end

          @key = rc_entry['key']
        else
          load_host_and_key_from_rc
        end

        cmd_puts("")
      end

      def start
        EM.run do
          ws = WebSocket::EventMachine::Client.connect(uri: LISTEN_URI)

          Signal.trap('INT') {
            ws.close
            exit(0)
          }

          Signal.trap('TERM') {
            ws.close
            exit(0)
          }

          ws.onopen do
            ws.send(listen_cmd)
          end

          ws.onmessage do |msg, type|
            cmd, *args = msg.split(' ')

            case cmd
            when SUCCESS_CMD
              if @host.blank?
                @host = args.last # per the protocol spec
              end

              print_connected_msg(hostname: @host)
            when ERR_CMD
              cmd_puts("{{x}} {{red:Error:}} {{underline:#{args.join(' ')}}}")
              ws.close
              exit(1)
            when WEBHOOK_CMD
              json_webhook = Base64.urlsafe_decode64(args.join(' '))
              webhook_container = MultiJson.load(json_webhook)
              service = webhook_container['service']
              headers = webhook_container['headers']
              body = webhook_container['body']

              # Send to Xip
              req = HTTP.timeout(connect: 5, read: 5).headers(headers)
              res = nil
              begin
                res = req.post(local_xip_uri(service: service), body: body)
              rescue HTTP::Error
                cmd_puts("{{x}} {{red:#{DateTime.now.iso8601}}}: {{cyan:#{service}}} → {{reset:POST localhost:#{@port}/incoming/#{service}}}")
                cmd_puts("{{red:Couldn't reach your local Xip server, is it running?}}")
              end

              unless res.nil?
                if res.status.success?
                  cmd_puts("{{*}} {{blue:#{DateTime.now.iso8601}}}: {{cyan:#{service}}} → {{reset:POST localhost:#{@port}/incoming/#{service}}}")
                else
                  cmd_puts("{{x}} {{red:#{DateTime.now.iso8601}}}: {{red:HTTP #{res.code}}} {{cyan:#{service}}} → {{reset:POST localhost:#{@port}/incoming/#{service}}}")
                end
              end
            end
          end

          ws.onclose do |code, reason|
            cmd_puts("{{magenta:Could not reach Xip server. Disconnecting.}}")
            exit(0)
          end
        end
      end

      private def load_host_and_key_from_rc
        if @xiprc.size == 0
          @host = @key = nil
          cmd_puts("{{yellow:No hosts registered. Generating a temporary host.}}")
          cmd_puts("{{yellow:You can register a permanent host with}} {{command:`xip register`}}")
        elsif @xiprc.size == 1
          # Only a single host has been registered, load it
          @host = @xiprc.first['host']
          @key = @xiprc.first['key']
        elsif @xiprc.size > 1
          @host = @xiprc.first['host']
          @key = @xiprc.first['key']
          cmd_puts("{{yellow:Multiple hosts registered. Defaulting to `#{@host}`}}")
          cmd_puts("{{yellow:You can specify a host with}} {{command:-h}}")
        end
      end

      private def listen_cmd
        if @host.present? && @key.present?
          signature = [@host, @key].join(':')
          "#{LISTEN_CMD} #{signature}"
        else
          LISTEN_CMD
        end
      end

      private def print_connected_msg(hostname:)
        CLI::UI::Frame.open("{{v}} {{bold:https://#{hostname}.xip.dev → http://localhost:#{@port}}}", color: :green) do
          cmd_puts("{{green:Connected}}")
        end
      end

      private def local_xip_uri(service:)
        "http://localhost:#{@port}/incoming/#{service}"
      end

    end
  end
end
