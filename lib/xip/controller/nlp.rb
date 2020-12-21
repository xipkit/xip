# frozen_string_literal: true

module Xip
  class Controller
    module Nlp

      extend ActiveSupport::Concern

      included do
        # Memoized in order to prevent multiple requests to the NLP provider
        def perform_nlp!
          Xip::Logger.l(
            topic: :nlp,
            message: "User #{current_session_id} -> Performing NLP."
          )

          unless Xip.config.nlp_integration.present?
            raise Xip::Errors::ConfigurationError, "An NLP integration has not yet been configured (Xip.config.nlp_integration)"
          end

          @nlp_result ||= begin
            nlp_client = nlp_client_klass.new
            @nlp_result = @current_message.nlp_result = nlp_client.understand(
              query: current_message.message
            )

            if Xip.config.log_all_nlp_results
              Xip::Logger.l(
                topic: :nlp,
                message: "User #{current_session_id} -> NLP Result: #{@nlp_result.parsed_result.inspect}"
              )
            end

            @nlp_result
          end
        end

        private

        def nlp_client_klass
          integration = Xip.config.nlp_integration.to_s.titlecase
          klass = "Xip::Nlp::#{integration}::Client"
          klass.classify.constantize
        end
      end

    end
  end
end
