# frozen_string_literal: true

require 'spec_helper'

$:.unshift File.expand_path("../support/helpers", __dir__)

describe "Xip::Controller helpers" do

  Xip::Controller.helpers_path = File.expand_path("../support/helpers", __dir__)

  module Fun
    class GamesController < Xip::Controller
      helper :all

      def say_hello_world
        hello_world
      end

      def say_kaboom
        hello_world2
      end
    end

    class PdfController < Xip::Controller
      def say_pdf_name
        generate_pdf_name
      end
    end
  end

  class BaseController < Xip::Controller

  end

  class AllHelpersController < Xip::Controller
    helper :all
  end

  class InheritedHelpersController < AllHelpersController
    def say_hello_world
      hello_world
    end
  end

  class SizzleController < Xip::Controller
    helper :standalone

    def say_sizzle

    end
  end

  class HelpersTypoController < Xip::Controller
    path = File.expand_path("../support/helpers_typo", __dir__)
    $:.unshift(path)
    self.helpers_path = path
  end

  class VoodooController < Xip::Controller
    helpers_path = File.expand_path("../support/alternate_helpers", __dir__)

    # Reload helpers
    _helpers = Module.new
    helper :all

    def zoom

    end
  end

  let(:facebook_message) { SampleMessage.new(service: 'facebook') }
  let(:all_helper_methods) { [:hello_world, :baz, :generate_pdf_name] }

  describe "loading" do

    it "should load all helpers if none are specified by default" do
      expect(BaseController._helpers.instance_methods).to match_array(all_helper_methods)
    end

    it "should not load helpers if none are specified by default and include_all_helpers = false" do
      Xip::Controller.include_all_helpers = false
      class HelperlessController < Xip::Controller; end
      expect(HelperlessController._helpers.instance_methods).to eq []
    end

    it "should load all helpers if :all is used" do
      expect(AllHelpersController._helpers.instance_methods).to match_array(all_helper_methods)
    end

    it "should load all helpers if parent class inherits all helpers" do
      expect(InheritedHelpersController._helpers.instance_methods).to match_array(all_helper_methods)
    end

    it "should allow a controller that has inherited all helpers to access a helper method" do
      expect {
        InheritedHelpersController.new(service_message: facebook_message.message_with_text).say_hello_world
      }.to_not raise_error
    end

    it "should allow a controller that has loaded all helpers to access a helper method" do
      expect {
        Fun::GamesController.new(service_message: facebook_message.message_with_text).say_hello_world
      }.to_not raise_error
    end

    it "should raise an error if a helper method does not exist" do
      expect {
        Fun::GamesController.new(service_message: facebook_message.message_with_text).say_kaboom
      }.to raise_error(NameError)
    end

    it "should allow a controller action to access a helper method" do
      expect {
        Fun::PdfController.new(service_message: facebook_message.message_with_text).say_pdf_name
      }.to_not raise_error
    end
  end

end
