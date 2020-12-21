# frozen_string_literal: true

require 'spec_helper'

describe "Xip::Controller::UnrecognizedMessage" do

  let(:fb_message) { SampleMessage.new(service: 'facebook') }
  let(:controller) { VadersController.new(service_message: fb_message.message_with_text) }

  describe 'run_unrecognized_message' do
    let(:e) {
      e = OpenStruct.new
      e.class = RuntimeError
      e.message = 'oops'
      e.backtrace = [
        '/xip/lib/xip/controller/controller.rb',
        '/xip/lib/xip/controller/catch_all.rb',
      ]
      e
    }

    describe 'when UnrecognizedMessagesController is not defined' do
      before(:each) do
        Object.send(:remove_const, :UnrecognizedMessagesController)
      end

      it "should log and run catch_all" do
        expect(Xip::Logger).to receive(:l).with(
          topic: 'unrecognized_message',
          message: "The message \"Hello World!\" was not recognized in the original context."
        ).ordered

        expect(Xip::Logger).to receive(:l).with(
          topic: 'unrecognized_message',
          message: 'Running catch_all; UnrecognizedMessagesController not defined.'
        ).ordered

        expect(controller).to receive(:run_catch_all).with(err: e)
        controller.run_unrecognized_message(err: e)
      end
    end

    it "should call handle_unrecognized_message on the UnrecognizedMessagesController" do
      class UnrecognizedMessagesController < Xip::Controller
        def handle_unrecognized_message
          do_nothing
        end
      end

      expect(Xip::Logger).to receive(:l).with(
        topic: 'unrecognized_message',
        message: "The message \"Hello World!\" was not recognized in the original context."
      ).ordered

      expect(Xip::Logger).to receive(:l).with(
        topic: 'unrecognized_message',
        message: 'A match was detected. Skipping catch-all.'
      ).ordered

      controller.run_unrecognized_message(err: e)
    end

    it "should log if the UnrecognizedMessagesController#handle_unrecognized_message does not progress the session" do
      class UnrecognizedMessagesController < Xip::Controller
        def handle_unrecognized_message
          # Oops
        end
      end

      expect(Xip::Logger).to receive(:l).with(
        topic: 'unrecognized_message',
        message: "The message \"Hello World!\" was not recognized in the original context."
      ).ordered

      expect(Xip::Logger).to receive(:l).with(
        topic: 'unrecognized_message',
        message: 'Did not send replies, update session, or step'
      ).ordered

      expect(controller).to_not receive(:run_catch_all)

      controller.run_unrecognized_message(err: e)
    end

    describe 'handoff to catch_all' do
      before(:each) do
        @session = Xip::Session.new(id: controller.current_session_id)
        @session.set_session(new_flow: 'vader', new_state: 'action_with_unrecognized_msg')

        @error_slug = [
          'error',
          controller.current_session_id,
          'vader',
          'action_with_unrecognized_msg'
        ].join('-')

        $redis.del(@error_slug)
      end

      it "should catch StandardError within UnrecognizedMessagesController and run catch_all" do
        $err = Xip::Errors::ReplyNotFound.new('oops')

        class UnrecognizedMessagesController < Xip::Controller
          def handle_unrecognized_message
            raise $err
          end
        end

        expect(Xip::Logger).to receive(:l).with(
          topic: 'unrecognized_message',
          message: "The message \"Hello World!\" was not recognized in the original context."
        ).ordered

        expect(controller).to receive(:run_catch_all).with(err: $err)

        controller.run_unrecognized_message(err: e)
      end

      it "should track the catch_all level against the original session during exceptions" do
        class UnrecognizedMessagesController < Xip::Controller
          def handle_unrecognized_message
            raise 'oops'
          end
        end

        expect($redis.get(@error_slug)).to be_nil
        controller.run_unrecognized_message(err: e)
        expect($redis.get(@error_slug)).to eq '1'
      end

      it "should track the catch_all level against the original session for UnrecognizedMessage errors" do
        class UnrecognizedMessagesController < Xip::Controller
          def handle_unrecognized_message
            handle_message(
              'x' => proc { do_nothing },
              'y' => proc { do_nothing }
            )
          end
        end

        expect($redis.get(@error_slug)).to be_nil
        controller.action(action: :action_with_unrecognized_msg)
        expect($redis.get(@error_slug)).to eq '1'
      end

      it "should NOT run catch_all if UnrecognizedMessagesController handles the message" do
        $x = 0
        class UnrecognizedMessagesController < Xip::Controller
          def handle_unrecognized_message
            handle_message(
              'Hello World!' => proc {
                $x = 1
                do_nothing
              },
              'y' => proc { do_nothing }
            )
          end
        end

        expect($redis.get(@error_slug)).to be_nil
        controller.action(action: :action_with_unrecognized_msg)
        expect($redis.get(@error_slug)).to be_nil
        expect($x).to eq 1
      end
    end
  end

end
