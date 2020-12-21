# frozen_string_literal: true

require 'xip/flow/specification'
require 'xip/flow/state'

module Xip
  module Flow

    extend ActiveSupport::Concern

    class_methods do
      def flow(flow_name, &specification)
        flow_spec[flow_name.to_sym] = Specification.new(flow_name, &specification)
      end
    end

    included do
      class_attribute :flow_spec, default: {}

      attr_accessor :flow, :flow_state, :user_id

      def current_state
        res = self.spec.states[@flow_state.to_sym] if @flow_state
        res || self.spec.initial_state
      end

      def current_flow
        @flow || self.class.flow_spec.keys.first
      end

      def spec
        self.class.flow_spec[current_flow]
      end

      def states
        self.spec.states.keys
      end

      def init(flow:, state:)
        new_flow = flow.to_sym
        new_state = state.to_sym

        unless state_exists?(potential_flow: new_flow, potential_state: new_state)
          raise(Xip::Errors::InvalidStateTransition, "Unknown state '#{new_state}' for '#{new_flow}' flow")
        end

        @flow = new_flow
        @flow_state = new_state

        self
      end

      private

        def flow_and_state
          [current_flow, current_state].join(Xip::Session::SLUG_SEPARATOR)
        end

        def state_exists?(potential_flow:, potential_state:)
          if self.class.flow_spec[potential_flow].present?
            self.class.flow_spec[potential_flow].states.include?(potential_state)
          else
            raise(Xip::Errors::InvalidStateTransition, "Unknown flow '#{potential_flow}'")
          end
        end
    end

  end
end
