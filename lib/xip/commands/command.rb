# frozen_string_literal: true

require 'xip'
require 'cli/ui'

module Xip
  module Commands
    class Command

      LISTEN_URI = if Xip.env.production?
        'wss://xip.dev/listen'
      else
        'ws://0.0.0.0:3000/listen'
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
