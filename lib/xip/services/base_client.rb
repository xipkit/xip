# frozen_string_literal: true

require 'xip/services/base_reply_handler'
require 'xip/services/base_message_handler'

require 'xip/services/jobs/handle_message_job'

module Xip
  module Services
    class BaseClient

      attr_reader :reply

      def initialize(reply:)
        @reply = reply
      end

      def transmit
        raise(Xip::Errors::ServiceImpaired, "Service implementation does not implement 'transmit'")
      end

    end
  end
end
