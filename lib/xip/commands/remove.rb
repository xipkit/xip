# frozen_string_literal: true

require 'xip/commands/command'
require 'yaml'

module Xip
  module Commands
    # Command for removing hostnames from your local config. Does NOT delete from xipkit.com
    #
    # It is run with:
    #
    #   `bundle exec xip remove`
    class Remove < Command

      attr_reader :options

      def initialize(options)
        super(options)

        @host   = options['host']
        @xiprc  = load_xiprc
      end

      def start
        entry_count = @xiprc.size

        if entry_count.zero?
          cmd_puts("{{x}} {{red:No hostnames found in your locall config. Skipping.}}")
          exit(1)
        end

        @xiprc = @xiprc.delete_if { |entry| entry['host'] == @host }

        if @xiprc.size == entry_count
          cmd_puts("{{x}} {{red:The hostname}} {{command:#{@host}}} {{red:was not found in your local config.}}")
          exit(1)
        end

        save_xiprc

        cmd_puts("{{v}} {{green:The hostname was removed. Please delete it from xipkit.com!}}")
      end

      private def save_xiprc
        File.open(XIPRC, 'w') { |file| file.write(@xiprc.to_yaml) }
      end

    end
  end
end
