# frozen_string_literal: true

module Xip
  class ServiceMessage

    attr_accessor :sender_id, :target_id, :timestamp, :service, :message,
                  :location, :attachments, :payload, :referral, :nlp_result,
                  :catch_all_reason

    def initialize(service:)
      @service = service
      @attachments = []
      @location = {}
    end

  end
end
