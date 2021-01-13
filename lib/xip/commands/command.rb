# frozen_string_literal: true

require 'xip'

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

      end
    end
  end
end
