# frozen_string_literal: true

module Xip
  class Controller
    module InterruptDetect

      extend ActiveSupport::Concern

      include Xip::Redis

      included do

        attr_reader :current_lock

        def current_lock
          @current_lock ||= Xip::Lock.find_lock(
            session_id: current_session_id
          )
        end

        def run_interrupt_action
          Xip::Logger.l(
            topic: 'interrupt',
            message: "Interrupt detected for session #{current_session_id}"
          )

          unless defined?(InterruptsController)
            Xip::Logger.l(
              topic: 'interrupt',
              message: 'Ignoring interrupt; InterruptsController not defined.'
            )

            return false
          end

          interrupt_controller = InterruptsController.new(
            service_message: current_message
          )

          begin
            # Run say_interrupted action
            interrupt_controller.say_interrupted

            unless interrupt_controller.progressed?
              # Log, but we cannot run the catch_all here
              Xip::Logger.l(
                topic: 'interrupt',
                message: 'Did not send replies, update session, or step'
              )
            end
          rescue StandardError => e
            # Log, but we cannot run the catch_all here
            Xip::Logger.l(
              topic: 'interrupt',
              message: [e.message, e.backtrace.join("\n")].join("\n")
            )
          end
        end

        private

          def interrupt_detected?
            # No interruption if there isn't an existing lock for this session
            return false if current_lock.blank?

            # No interruption if we are in the same thread
            return false if current_thread_has_control?

            true
          end

          def current_thread_has_control?
            current_lock.tid == Xip.tid
          end

          def lock_session!(session_slug:, position: nil)
            lock = Xip::Lock.new(
              session_id: current_session_id,
              session_slug: session_slug,
              position: position
            )

            lock.create
          end

          # Yields control to other threads to take action on this session
          # by releasing the lock.
          def release_lock!
            # We don't want to release the lock from within InterruptsController
            # otherwise the InterruptsController can get interrupted.
            unless self.class.to_s == 'InterruptsController'
              current_lock&.release
            end
          end
      end

    end
  end
end
