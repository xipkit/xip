# frozen_string_literal: true

require 'sinatra/base'
require 'multi_json'

module Xip
  class Server < Sinatra::Base

    def self.get_or_post(url, &block)
      get(url, &block)
      post(url, &block)
    end

    get '/' do
      <<~WELCOME
        <html>
          <head>
            <title>Xip</title>
          </head>
          <body>
            <center>
              <a href='https://xipkit.com'>
                <img src='http://cdn.xipkit.com/logo-light.svg' height='120' alt='Xip Logo' aria-label='xipkit.com' />
              </a>
            </center>
          </body>
        </html>
      WELCOME
    end

    get_or_post '/incoming/:service' do
      Xip::Logger.l(topic: params[:service], message: 'Received webhook.')

      # JSON params need to be parsed and added to the params
      if request.env['CONTENT_TYPE']&.match(/application\/json/i)
        json_params = MultiJson.load(request.body.read)
        params.merge!(json_params)
      end

      dispatcher = Xip::Dispatcher.new(
        service: params[:service],
        params: params,
        headers: get_helpers_from_request(request)
      )

      headers 'Access-Control-Allow-Origin' => '*',
              'Access-Control-Allow-Methods' => ['OPTIONS', 'GET', 'POST']
      # content_type 'audio/mp3'
      content_type 'application/octet-stream'

      dispatcher.coordinate
    end

    private

      def get_helpers_from_request(request)
        request.env.select do |header, value|
          %w[HTTP_HOST].include?(header)
        end
      end

  end
end
