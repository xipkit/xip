require 'rack/handler/puma'
require_relative 'config/boot'

Rack::Handler::Puma.run(Xip::Server)
