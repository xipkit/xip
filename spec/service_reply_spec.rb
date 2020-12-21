# frozen_string_literal: true

require 'spec_helper'

describe "Xip::ServiceReply" do

  let(:recipient_id) { "8b3e0a3c-62f1-401e-8b0f-615c9d256b1f" }
  let(:yaml_reply) { File.read(File.join(File.dirname(__FILE__), 'replies', 'hello.yml.erb')) }

  describe "nested reply with ERB" do
    it "should load all the replies" do
      first_name = "Presley"

      service_reply = Xip::ServiceReply.new(
        recipient_id: recipient_id,
        yaml_reply: yaml_reply,
        context: binding,
        preprocessor: :erb
      )

      expect(service_reply.replies.size).to eq 5
    end

    it "should load all replies as Xip::Reply objects" do
      first_name = "Presley"

      service_reply = Xip::ServiceReply.new(
        recipient_id: recipient_id,
        yaml_reply: yaml_reply,
        context: binding,
        preprocessor: :erb
      )

      expect(service_reply.replies).to all(be_an(Xip::Reply))
    end

    it "should replace the ERB tag" do
      first_name = "Presley"

      service_reply = Xip::ServiceReply.new(
        recipient_id: recipient_id,
        yaml_reply: yaml_reply,
        context: binding,
        preprocessor: :erb
      )

      phrase_in_reply = service_reply.replies.first['text']
      expect(phrase_in_reply).to eq "Hi, Presley. Welcome to Xip bot..."
    end

    it "should raise Xip::Errors::UndefinedVariable when local variable is not available" do
      expect {
        service_reply = Xip::ServiceReply.new(
          recipient_id: recipient_id,
          yaml_reply: yaml_reply,
          context: binding,
          preprocessor: :erb
        )
      }.to raise_error(Xip::Errors::UndefinedVariable)
    end
  end

  describe "processing a reply without a preprocessor specified" do
    it "should not replace the ERB tag when no preprocessor is specified" do
      first_name = "Gisele"

      service_reply = Xip::ServiceReply.new(
        recipient_id: recipient_id,
        yaml_reply: yaml_reply,
        context: binding
      )

      phrase_in_reply = service_reply.replies.first['text']
      expect(phrase_in_reply).to eq "Hi, <%= first_name %>. Welcome to Xip bot..."
    end

    it "should not replace the ERB tag when :none is specified as the preprocessor" do
      first_name = "Gisele"

      service_reply = Xip::ServiceReply.new(
        recipient_id: recipient_id,
        yaml_reply: yaml_reply,
        context: binding,
        preprocessor: :none
      )

      phrase_in_reply = service_reply.replies.first['text']
      expect(phrase_in_reply).to eq "Hi, <%= first_name %>. Welcome to Xip bot..."
    end
  end

end
