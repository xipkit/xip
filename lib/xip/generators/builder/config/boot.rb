require 'xip'
require_relative './environment'

Bundler.require(:default, Xip.env)

Xip.boot
