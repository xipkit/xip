# frozen_string_literal: true

require 'xip/commands/command'
require 'yaml'

module Xip
  module Commands
    # Command for registering hostnames for use with `xip listen`.
    #
    # It is run with:
    #
    #   `bundle exec xip register`
    class Register < Command

      attr_reader :options

      def initialize(options)
        super(options)

        @host   = options['host']
        @key    = options['key']
        @xiprc  = load_xiprc
      end

      def start
        if host_already_registered?
          cmd_puts("{{x}} {{red:The hostname}} {{command:#{@host}}} {{red:is already registered. Try}} {{command:xip remove --help}}")
          exit(1)
        end

        xiprc_entry = {
          'host'  => @host,
          'key'   => @key
        }

        @xiprc << xiprc_entry

        save_xiprc

        cmd_puts("{{v}} {{green:The hostname is now registered.}}")
      end

      private def host_already_registered?
        @xiprc.each do |xiprc_entry|
          if xiprc_entry['host'] == @host
            return true
          end
        end

        false
      end

      private def save_xiprc
        File.open(XIPRC, 'w') { |file| file.write(@xiprc.to_yaml) }
      end

    end
  end
end
