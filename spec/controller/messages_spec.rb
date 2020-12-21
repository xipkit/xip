# frozen_string_literal: true

require 'spec_helper'

describe Xip::Controller::Messages do

  class MrTronsController < Xip::Controller

  end

  let(:facebook_message) { SampleMessage.new(service: 'facebook') }
  let(:test_controller) {
    MrTronsController.new(service_message: facebook_message.message_with_text)
  }

  describe "normalized_msg" do
    let(:padded_msg) { '  Hello World! 👋  ' }
    let(:weird_case_msg) { 'Oh BaBy Oh BaBy' }

    it 'should normalize blank-padded messages' do
      test_controller.current_message.message = padded_msg
      expect(test_controller.normalized_msg).to eq('HELLO WORLD! 👋')
    end

    it 'should normalize differently cased messages' do
      test_controller.current_message.message = weird_case_msg
      expect(test_controller.normalized_msg).to eq('OH BABY OH BABY')
    end
  end

  describe "homophone_translated_msg" do
    it 'should convert homophones to their respective alpha ordinal' do
      Xip::Controller::Messages::HOMOPHONES.each do |homophone, ordinal|
        test_controller.current_message.message = homophone
        test_controller.normalized_msg = test_controller.homophone_translated_msg = nil
        expect(test_controller.homophone_translated_msg).to eq(ordinal)
      end
    end
  end

  describe "get_match" do
    it "should match messages with different casing" do
      test_controller.current_message.message = "NICE"
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('nice')
    end

    it "should match messages with blank padding" do
      test_controller.current_message.message = " NiCe   "
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('nice')
    end

    it "should match messages utilizing a lower case SMS quick reply" do
      test_controller.current_message.message = "a "
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('nice')
    end

    it "should match messages utilizing an upper case SMS quick reply" do
      test_controller.current_message.message = " B "
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('woot')
    end

    it "should match messages utilizing a single-quoted SMS quick reply" do
      test_controller.current_message.message = "'B'"
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('woot')
    end

    it "should match messages utilizing a double-quoted SMS quick reply" do
      test_controller.current_message.message = '"A"'
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('nice')
    end

    it "should match messages utilizing a double-smartquoted SMS quick reply" do
      test_controller.current_message.message = '“A”'
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('nice')
    end

    it "should match messages utilizing a single-smartquoted SMS quick reply" do
      test_controller.current_message.message = '‘A’'
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('nice')
    end

    it "should match messages with a period in the SMS quick reply" do
      test_controller.current_message.message = 'A.'
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('nice')
    end

    it "should match messages with a question mark in the SMS quick reply" do
      test_controller.current_message.message = 'B?'
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('woot')
    end

    it "should match messages in parens in the SMS quick reply" do
      test_controller.current_message.message = '(B)'
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('woot')
    end

    it "should match messages with backticks in the SMS quick reply" do
      test_controller.current_message.message = '`B`'
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('woot')
    end

    it "should match messages utilizing a homophone" do
      test_controller.current_message.message = " bee "
      expect(
        test_controller.get_match(['nice', 'woot'])
      ).to eq('woot')
    end

    it "should raise ReservedHomophoneUsed if a homophone is used" do
      test_controller.current_message.message = " B "
      expect {
        test_controller.get_match(['nice', 'woot', 'sea', 'bee'])
      }.to raise_error(Xip::Errors::ReservedHomophoneUsed, 'Cannot use `SEA, BEE`. Reserved for homophones.')
    end

    it "should raise Xip::Errors::UnrecognizedMessage if a response was not matched" do
      test_controller.current_message.message = "uh oh"
      expect {
        test_controller.get_match(['nice', 'woot'])
      }.to raise_error(Xip::Errors::UnrecognizedMessage)
    end

    it "should raise Xip::Errors::UnrecognizedMessage if an SMS quick reply was not matched" do
      test_controller.current_message.message = "C"
      expect {
        test_controller.get_match(['nice', 'woot'])
      }.to raise_error(Xip::Errors::UnrecognizedMessage)
    end

    it "should not run NLP entity detection if an ordinal is entered by the user" do
      test_controller.current_message.message = "C"

      expect(test_controller).to_not receive(:perform_nlp!)
      expect(
        test_controller.get_match([:yes, :no, 'unsubscribe'])
      ).to eq('unsubscribe')
    end

    describe "entity detection" do
      let(:no_intent) { :no }
      let(:yes_intent) { :yes }
      let(:single_number_nlp_result) { TestNlpResult::Luis.new(intent: yes_intent, entity: :single_number_entity) }
      let(:double_number_nlp_result) { TestNlpResult::Luis.new(intent: no_intent, entity: :double_number_entity) }
      let(:triple_number_nlp_result) { TestNlpResult::Luis.new(intent: yes_intent, entity: :triple_number_entity) }

      describe 'single nlp_result entity' do
        it 'should return the :number entity' do
          allow(test_controller).to receive(:perform_nlp!).and_return(single_number_nlp_result)
          test_controller.nlp_result = single_number_nlp_result

          test_controller.current_message.message = "hi"
          expect(
            test_controller.get_match(['nice', :number])
          ).to eq(test_controller.nlp_result.entities[:number].first)
        end

        it 'should return the first :number entity if fuzzy_match=true' do
          allow(test_controller).to receive(:perform_nlp!).and_return(double_number_nlp_result)
          test_controller.nlp_result = double_number_nlp_result

          test_controller.current_message.message = "hi"
          expect(
            test_controller.get_match(['nice', :number])
          ).to eq(test_controller.nlp_result.entities[:number].first)
        end

        it 'should raise Xip::Errors::UnrecognizedMessage if more than one :number entity is returned and fuzzy_match=false' do
          allow(test_controller).to receive(:perform_nlp!).and_return(double_number_nlp_result)
          test_controller.nlp_result = double_number_nlp_result

          test_controller.current_message.message = "hi"
          expect {
            test_controller.get_match(['nice', :number], fuzzy_match: false)
          }.to raise_error(Xip::Errors::UnrecognizedMessage, "Encountered 2 entity matches of type :number and expected 1. To allow, set fuzzy_match to true.")
        end

        it 'should log the NLP result if log_all_nlp_results=true' do
          Xip.config.log_all_nlp_results = true
          Xip.config.nlp_integration = :luis

          luis_client = double('luis_client')
          allow(luis_client).to receive(:understand).and_return(single_number_nlp_result)
          allow(Xip::Nlp::Luis::Client).to receive(:new).and_return(luis_client)

          expect(Xip::Logger).to receive(:l).with(
            topic: :nlp,
            message: "User 8b3e0a3c-62f1-401e-8b0f-615c9d256b1f -> Performing NLP."
          )
          expect(Xip::Logger).to receive(:l).with(
            topic: :nlp,
            message: "User 8b3e0a3c-62f1-401e-8b0f-615c9d256b1f -> NLP Result: #{single_number_nlp_result.parsed_result.inspect}"
          )
          test_controller.current_message.message = "hi"
          test_controller.get_match(['nice', :number])

          Xip.config.log_all_nlp_results = false
          Xip.config.nlp_integration = nil
        end
      end

      describe 'multiple nlp_result entity matches' do
        it 'should return the [:number, :number] entity' do
          allow(test_controller).to receive(:perform_nlp!).and_return(double_number_nlp_result)
          test_controller.nlp_result = double_number_nlp_result

          test_controller.current_message.message = "hi"
          expect(
            test_controller.get_match(['nice', [:number, :number]])
          ).to eq(double_number_nlp_result.entities[:number])
        end

        it 'should return the [:number, :number, :number] entity' do
          allow(test_controller).to receive(:perform_nlp!).and_return(triple_number_nlp_result)
          test_controller.nlp_result = triple_number_nlp_result

          test_controller.current_message.message = "hi"
          expect(
            test_controller.get_match(['nice', [:number, :number, :number]])
          ).to eq(triple_number_nlp_result.entities[:number])
        end

        it 'should return the [:number, :number] entity from a triple :number entity result' do
          allow(test_controller).to receive(:perform_nlp!).and_return(triple_number_nlp_result)
          test_controller.nlp_result = triple_number_nlp_result

          test_controller.current_message.message = "hi"
          expect(
            test_controller.get_match(['nice', [:number, :number]])
          ).to eq(triple_number_nlp_result.entities[:number].slice(0, 2))
        end

        it 'should return the :number entity from a triple :number entity result' do
          allow(test_controller).to receive(:perform_nlp!).and_return(triple_number_nlp_result)
          test_controller.nlp_result = triple_number_nlp_result

          test_controller.current_message.message = "hi"
          expect(
            test_controller.get_match(['nice', :number])
          ).to eq(triple_number_nlp_result.entities[:number].first)
        end

        it 'should return the [:number, :key_phrase] entities' do
          allow(test_controller).to receive(:perform_nlp!).and_return(triple_number_nlp_result)
          test_controller.nlp_result = triple_number_nlp_result

          test_controller.current_message.message = "hi"
          expect(
            test_controller.get_match(['nice', [:number, :key_phrase]])
          ).to eq([89, 'scores'])
        end

        it 'should raise Xip::Errors::UnrecognizedMessage if more than one :number entity is returned and fuzzy_match=false' do
          allow(test_controller).to receive(:perform_nlp!).and_return(triple_number_nlp_result)
          test_controller.nlp_result = triple_number_nlp_result

          test_controller.current_message.message = "hi"
          expect {
            test_controller.get_match(['nice', :number], fuzzy_match: false)
          }.to raise_error(Xip::Errors::UnrecognizedMessage, "Encountered 3 entity matches of type :number and expected 1. To allow, set fuzzy_match to true.")
        end

        it 'should raise Xip::Errors::UnrecognizedMessage if more than two :number entities are returned and fuzzy_match=false' do
          allow(test_controller).to receive(:perform_nlp!).and_return(triple_number_nlp_result)
          test_controller.nlp_result = triple_number_nlp_result

          test_controller.current_message.message = "hi"
          expect {
            test_controller.get_match(['nice', [:number, :number]], fuzzy_match: false)
          }.to raise_error(Xip::Errors::UnrecognizedMessage, "Encountered 1 additional entity matches of type :number for match [:number, :number]. To allow, set fuzzy_match to true.")
        end

        it 'should log the NLP result if log_all_nlp_results=true' do
          Xip.config.log_all_nlp_results = true
          Xip.config.nlp_integration = :luis

          luis_client = double('luis_client')
          allow(luis_client).to receive(:understand).and_return(triple_number_nlp_result)
          allow(Xip::Nlp::Luis::Client).to receive(:new).and_return(luis_client)

          expect(Xip::Logger).to receive(:l).with(
            topic: :nlp,
            message: "User 8b3e0a3c-62f1-401e-8b0f-615c9d256b1f -> Performing NLP."
          )
          expect(Xip::Logger).to receive(:l).with(
            topic: :nlp,
            message: "User 8b3e0a3c-62f1-401e-8b0f-615c9d256b1f -> NLP Result: #{triple_number_nlp_result.parsed_result.inspect}"
          )
          test_controller.current_message.message = "hi"
          test_controller.get_match(['nice', [:number, :number]])

          Xip.config.log_all_nlp_results = false
          Xip.config.nlp_integration = nil
        end
      end

      describe 'custom entities' do
        let(:custom_entity_nlp_result) { TestNlpResult::Luis.new(intent: yes_intent, entity: :custom_entity) }

        it 'should return the text matched by the custom entity' do
          allow(test_controller).to receive(:perform_nlp!).and_return(custom_entity_nlp_result)
          test_controller.nlp_result = custom_entity_nlp_result

          test_controller.current_message.message = "call me right away"
          expect(
            test_controller.get_match(['nice', :asap])
          ).to eq 'right away'
        end
      end
    end

    describe "mismatch" do
      describe 'raise_on_mismatch: true' do
        it "should raise a Xip::Errors::UnrecognizedMessage" do
          test_controller.current_message.message = 'C'
          expect {
            test_controller.get_match(['nice', 'woot'])
          }.to raise_error(Xip::Errors::UnrecognizedMessage)
        end

        it "should NOT log if an nlp_result is not present" do
          test_controller.current_message.message = 'spicy'
          expect(Xip::Logger).to_not receive(:l)
          expect {
            test_controller.get_match(['nice', 'woot'])
          }.to raise_error(Xip::Errors::UnrecognizedMessage)
        end

        it "should log if an nlp_result is present" do
          test_controller.current_message.message = 'spicy'
          nlp_result = double('nlp_result')
          allow(nlp_result).to receive(:parsed_result).and_return({})

          expect(Xip::Logger).to receive(:l).with(
            topic: :nlp,
            message: "User 8b3e0a3c-62f1-401e-8b0f-615c9d256b1f -> NLP Result: {}"
          )

          test_controller.nlp_result = nlp_result

          expect {
            test_controller.get_match(['nice', 'woot'])
          }.to raise_error(Xip::Errors::UnrecognizedMessage)
        end
      end

      describe 'raise_on_mismatch: false' do
        it "should not raise a Xip::Errors::UnrecognizedMessage" do
          test_controller.current_message.message = 'C'
          expect {
            test_controller.get_match(['nice', 'woot'], raise_on_mismatch: false)
          }.to_not raise_error(Xip::Errors::UnrecognizedMessage)
        end

        it "should return the original message" do
          test_controller.current_message.message = 'spicy'
          expect(
            test_controller.get_match(['nice', 'woot'], raise_on_mismatch: false)
          ).to eq 'spicy'
        end

        it "should NOT log if an nlp_result is not present" do
          test_controller.current_message.message = 'spicy'
          expect(Xip::Logger).to_not receive(:l)
          test_controller.get_match(['nice', 'woot'], raise_on_mismatch: false)
        end

        it "should log if an nlp_result is present" do
          test_controller.current_message.message = 'spicy'
          nlp_result = double('nlp_result')
          allow(nlp_result).to receive(:parsed_result).and_return({})

          expect(Xip::Logger).to receive(:l).with(
            topic: :nlp,
            message: "User 8b3e0a3c-62f1-401e-8b0f-615c9d256b1f -> NLP Result: {}"
          )

          test_controller.nlp_result = nlp_result

          test_controller.get_match(['nice', 'woot'], raise_on_mismatch: false)
        end
      end
    end
  end

  describe "handle_message" do
    it "should run the proc of the matched reply" do
      expect(STDOUT).to receive(:puts).with('Cool, Refinance 👍')

      test_controller.current_message.message = "B"
      test_controller.handle_message(
        'Buy' => proc { puts 'Buy' },
        'Refinance' => proc { puts 'Cool, Refinance 👍' }
      )
    end

    it "should run proc in the binding of the calling instance" do
      test_controller.current_message.message = "B"
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 }
      )

      expect(x).to eq 2
    end

    it "should match against single-quoted ordinals" do
      test_controller.current_message.message = "'B'"
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 }
      )

      expect(x).to eq 2
    end

    it "should match against double-quoted ordinals" do
      test_controller.current_message.message = '"A"'
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 }
      )

      expect(x).to eq 1
    end

    it "should match against double-smartquoted ordinals" do
      test_controller.current_message.message = '“A”'
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 }
      )

      expect(x).to eq 1
    end

    it "should match against single-smartquoted ordinals" do
      test_controller.current_message.message = '‘A’'
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 }
      )

      expect(x).to eq 1
    end

    it "should match against ordinals with periods" do
      test_controller.current_message.message = 'A.'
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 }
      )

      expect(x).to eq 1
    end

    it "should match against ordinals with question marks" do
      test_controller.current_message.message = 'A?'
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 }
      )

      expect(x).to eq 1
    end

    it "should match against ordinals with parens" do
      test_controller.current_message.message = '(A)'
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 }
      )

      expect(x).to eq 1
    end

    it "should match against ordinals with backticks" do
      test_controller.current_message.message = '`A`'
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 }
      )

      expect(x).to eq 1
    end

    it "should match homophones" do
      test_controller.current_message.message = 'sea'
      x = 0
      test_controller.handle_message(
        'Buy' => proc { x += 1 },
        'Refinance' => proc { x += 2 },
        'Other' => proc { x += 3 }
      )

      expect(x).to eq 3
    end

    it "should raise ReservedHomophoneUsed error if an arm contains a reserved homophone" do
      test_controller.current_message.message = "B"
      x = 0

      expect {
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          :woot => proc { x += 2 },
          'Sea' => proc { x += 3 }
        )
      }.to raise_error(Xip::Errors::ReservedHomophoneUsed, 'Cannot use `SEA`. Reserved for homophones.')
    end

    it "should not run NLP if an ordinal is entered by the user" do
      test_controller.current_message.message = "C"
      x = 0
      test_controller.handle_message(
        :yes => proc { x += 1 },
        :no => proc { x += 2 },
        'Unsubscribe' => proc { x += 3 }
      )

      expect(test_controller).to_not receive(:perform_nlp!)
      expect(x).to eq 3
    end

    describe "intent detection" do
      let(:no_intent) { :no }
      let(:yes_intent) { :yes }
      let(:yes_intent_nlp_result) { TestNlpResult::Luis.new(intent: yes_intent, entity: :single_number_entity) }
      let(:no_intent_nlp_result) { TestNlpResult::Luis.new(intent: no_intent, entity: :double_number_entity) }

      it 'should support :yes intent' do
        test_controller.current_message.message = "YAS"
        allow(test_controller).to receive(:perform_nlp!).and_return(yes_intent_nlp_result)
        test_controller.nlp_result = yes_intent_nlp_result

        x = 0
        test_controller.send(
          :handle_message, {
            'Buy' => proc { x += 1 },
            :yes => proc { x += 9 },
            :no => proc { x += 8 }
          }
        )

        expect(x).to eq 9
      end

      it 'should support :no intent' do
        test_controller.current_message.message = "NAH"
        allow(test_controller).to receive(:perform_nlp!).and_return(no_intent_nlp_result)
        test_controller.nlp_result = no_intent_nlp_result

        x = 0
        test_controller.send(
          :handle_message, {
            'Buy' => proc { x += 1 },
            :yes => proc { x += 9 },
            :no => proc { x += 8 }
          }
        )

        expect(x).to eq 8
      end

      it 'should log the NLP result if log_all_nlp_results=true' do
        Xip.config.log_all_nlp_results = true
        Xip.config.nlp_integration = :luis

        luis_client = double('luis_client')
        allow(luis_client).to receive(:understand).and_return(yes_intent_nlp_result)
        allow(Xip::Nlp::Luis::Client).to receive(:new).and_return(luis_client)

        expect(Xip::Logger).to receive(:l).with(
          topic: :nlp,
          message: "User 8b3e0a3c-62f1-401e-8b0f-615c9d256b1f -> Performing NLP."
        )
        expect(Xip::Logger).to receive(:l).with(
          topic: :nlp,
          message: "User 8b3e0a3c-62f1-401e-8b0f-615c9d256b1f -> NLP Result: #{yes_intent_nlp_result.parsed_result.inspect}"
        )
        test_controller.current_message.message = "YAS"
        x = 0
        test_controller.send(
          :handle_message, {
            'Buy' => proc { x += 1 },
            :yes => proc { x += 9 },
            :no => proc { x += 8 }
          }
        )

        Xip.config.log_all_nlp_results = false
        Xip.config.nlp_integration = nil
      end
    end

    describe 'Regexp matcher' do
      it "should match when the Regexp matches" do
        test_controller.current_message.message = "About Encom"
        x = 0
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          'Refinance' => proc { x += 2 },
          /about/i => proc { x += 10 }
        )
        expect(x).to eq 10
      end

      it "should match positional Regexes" do
        test_controller.current_message.message = "Jump about"
        x = 0
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          /\Aabout/i => proc { x += 2 },
          /about/i => proc { x += 10 }
        )
        expect(x).to eq 10
      end

      it "should match as an alpha ordinal" do
        test_controller.current_message.message = "C"
        x = 0
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          'Refinance' => proc { x += 2 },
          /about/i => proc { x += 10 }
        )
        expect(x).to eq 10
      end
    end

    describe 'nil matcher' do
      it "should match the respective ordinal" do
        test_controller.current_message.message = "C"
        x = 0
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          'Refinance' => proc { x += 2 },
          nil => proc { x += 10 }
        )
        expect(x).to eq 10
      end

      it "should match an unknown ordinal" do
        test_controller.current_message.message = "D"
        x = 0
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          'Refinance' => proc { x += 2 },
          nil => proc { x += 10 }
        )
        expect(x).to eq 10
      end

      it "should match free-form text" do
        test_controller.current_message.message = "Hello world!"
        x = 0
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          'Refinance' => proc { x += 2 },
          nil => proc { x += 10 }
        )
        expect(x).to eq 10
      end
    end

    it "should raise Xip::Errors::UnrecognizedMessage if the reply does not match" do
      test_controller.current_message.message = "C"
      x = 0
      expect {
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          'Refinance' => proc { x += 2 }
        )
      }.to raise_error(Xip::Errors::UnrecognizedMessage)
    end

    it "should NOT log if an nlp_result is not present" do
      test_controller.current_message.message = 'spicy'
      expect(Xip::Logger).to_not receive(:l)

      x = 0
      expect {
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          'Refinance' => proc { x += 2 }
        )
      }.to raise_error(Xip::Errors::UnrecognizedMessage)
    end

    it "should log if an nlp_result is present" do
      test_controller.current_message.message = 'spicy'
      nlp_result = double('nlp_result')
      allow(nlp_result).to receive(:parsed_result).and_return({})

      expect(Xip::Logger).to receive(:l).with(
        topic: :nlp,
        message: "User 8b3e0a3c-62f1-401e-8b0f-615c9d256b1f -> NLP Result: {}"
      )

      test_controller.nlp_result = nlp_result

      x = 0
      expect {
        test_controller.handle_message(
          'Buy' => proc { x += 1 },
          'Refinance' => proc { x += 2 }
        )
      }.to raise_error(Xip::Errors::UnrecognizedMessage)
    end
  end

end
