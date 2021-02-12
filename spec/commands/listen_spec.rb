# frozen_string_literal: true

require 'spec_helper'
require 'xip/commands/listen'

describe "Xip::Commands::Listen" do

  let(:host1) { 'host1' }
  let(:key1) { SecureRandom.hex(14) }
  let(:host2) { 'host2' }
  let(:key2) { SecureRandom.hex(14) }
  let(:sample_xiprc) {
    [
      { 'host' => host1, 'key' => key1 },
      { 'host' => host2, 'key' => key2 }
    ]
  }

  describe 'when a hostname is specified' do
    let(:default_options) {
      { 'port' => '5000', host: @host2 }
    }

    before(:each) do
      allow_any_instance_of(Xip::Commands::Listen).to receive(:parse_auth_file).and_return(sample_xiprc)
      @listen = Xip::Commands::Listen.new(default_options)
    end

    describe 'when the hostname is present in .xiprc' do
      it 'should set the @host instance variable' do
        expect(@listen.host).to eq @host2
      end

      it 'should set the corresponding key' do
        expect(@listen.key).to eq @key2
      end
    end

    describe 'when the hostname is NOT present in .xiprc' do
      it 'should exit early and print a message' do

      end
    end
  end

  describe 'when a hostname is not specified' do

  end

end
