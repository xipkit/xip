# frozen_string_literal: true

module Xip
  module Services

    class HandleMessageJob < Xip::Jobs
      sidekiq_options queue: :xip_webhooks, retry: false

      def perform(service, params, headers)
        dispatcher = Xip::Dispatcher.new(
          service: service,
          params: params,
          headers: headers
        )

        dispatcher.process
      end
    end

  end
end
