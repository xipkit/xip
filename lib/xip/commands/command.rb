# frozen_string_literal: true

require 'xip'
require 'cli/ui'

module Xip
  module Commands
    class Command

      LISTEN_URI = if ENV['LISTEN_URI'].present?
        ENV['LISTEN_URI']
      else
        'wss://xip.dev/listen'
      end

      XIPRC = File.join(Dir.home, '.xiprc')

      def initialize(options)
        CLI::UI::StdoutRouter.enable
      end

      private def cmd_puts(str)
        puts CLI::UI.fmt(str)
      end

      private def load_xiprc
        begin
          file_contents = File.read(XIPRC)
          YAML.load(file_contents)
        rescue Errno::ENOENT
          [] # .xiprc does not yet exist
        end
      end
    end
  end
end
