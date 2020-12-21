# frozen_string_literal: true

# base requirements
require 'yaml'
require 'sidekiq'
require 'active_support/all'

begin
  require "rails"
  require "active_record"
rescue LoadError
  # Don't require ActiveRecord
end

# core
require 'xip/version'
require 'xip/errors'
require 'xip/core_ext'
require 'xip/logger'
require 'xip/configuration'
require 'xip/reloader'

# helpers
require 'xip/helpers/redis'

module Xip

  def self.env
    @env ||= ActiveSupport::StringInquirer.new(ENV['XIP_ENV'] || 'development')
  end

  def self.root
    @root ||= File.expand_path(Pathname.new(Dir.pwd))
  end

  def self.boot
    load_services_config
    load_environment
  end

  def self.config
    Thread.current[:configuration] ||= load_services_config
  end

  def self.configuration=(config)
    Thread.current[:configuration] = config
  end

  def self.default_autoload_paths
    [
      File.join(Xip.root, 'bot', 'controllers', 'concerns'),
      File.join(Xip.root, 'bot', 'controllers'),
      File.join(Xip.root, 'bot', 'models', 'concerns'),
      File.join(Xip.root, 'bot', 'models'),
      File.join(Xip.root, 'bot', 'helpers'),
      File.join(Xip.root, 'config')
    ]
  end

  def self.bot_reloader
    @bot_reloader
  end

  def self.set_config_defaults(config)
    defaults = {
      dynamic_delay_muliplier: 1.0,                     # values > 1 increase, values < 1 decrease delay
      session_ttl: 0,                                   # 0 seconds; don't expire sessions
      lock_autorelease: 30,                             # 30 seconds
      transcript_logging: false,                        # show user replies in the logs
      hot_reload: Xip.env.development?,                 # hot reload bot files on change (dev only)
      eager_load: Xip.env.production?,                  # eager load bot files for performance (prod only)
      autoload_paths: Xip.default_autoload_paths,       # array of autoload paths used in eager and hot reloading
      autoload_ignore_paths: [],                        # paths to exclude from eager and hot reloading
      nlp_integration: nil,                             # NLP service to use, defaults to none
      log_all_nlp_results: false,                       # log NLP service requests; useful for debugging/improving NLP models
      auto_insert_delays: true                          # automatically insert delays/typing indicators between all replies
    }
    defaults.each { |option, default| config.set_default(option, default) }
  end

  # Loads the services.yml configuration unless one has already been loaded
  def self.load_services_config(services_yaml=nil)
    @semaphore ||= Mutex.new
    services_yaml ||= Xip.load_services_config(
      File.read(File.join(Xip.root, 'config', 'services.yml'))
    )

    Thread.current[:configuration] ||= begin
      @semaphore.synchronize do
        services_config = YAML.load(ERB.new(services_yaml).result)

        unless services_config.has_key?(env)
          raise Xip::Errors::ConfigurationError, "Could not find services.yml configuration for #{env} environment"
        end

        config = Xip::Configuration.new(services_config[env])
        set_config_defaults(config)

        config
      end
    end
  end

  # Same as `load_services_config` but forces the loading even if one has
  # already been loaded
  def self.load_services_config!(services_yaml=nil)
    Thread.current[:configuration] = nil
    load_services_config(services_yaml)
  end

  def self.load_bot!
    @bot_reloader ||= begin
      bot_reloader = Xip::Reloader.new
      bot_reloader.load_bot!
      bot_reloader
    end
  end

  def self.load_environment
    require File.join(Xip.root, 'config', 'boot')
    require_directory('config/initializers')

    load_bot!

    Sidekiq.options[:reloader] = Xip.bot_reloader

    if defined?(ActiveRecord)
      if ENV['DATABASE_URL'].present?
        ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])
      else
        database_config = File.read(File.join(Xip.root, 'config', 'database.yml'))
        ActiveRecord::Base.establish_connection(
          YAML.load(ERB.new(database_config).result)[Xip.env]
        )
      end
    end
  end

  def self.tid
    Thread.current.object_id.to_s(36)
  end

  def self.require_directory(directory)
    for_each_file_in(directory) { |file| require_relative(file) }
  end

private

  def self.for_each_file_in(directory, &blk)
    directory = directory.to_s.gsub(%r{(\/|\\)}, File::SEPARATOR)
    directory = Pathname.new(Dir.pwd).join(directory).to_s
    directory = File.join(directory, '**', '*.rb') unless directory =~ /(\*\*)/

    Dir.glob(directory).sort.each(&blk)
  end

end

require 'xip/jobs'
require 'xip/dispatcher'
require 'xip/server'
require 'xip/reply'
require 'xip/scheduled_reply'
require 'xip/service_reply'
require 'xip/service_message'
require 'xip/session'
require 'xip/lock'
require 'xip/nlp/result'
require 'xip/nlp/client'
require 'xip/controller/callbacks'
require 'xip/controller/replies'
require 'xip/controller/messages'
require 'xip/controller/unrecognized_message'
require 'xip/controller/catch_all'
require 'xip/controller/helpers'
require 'xip/controller/dynamic_delay'
require 'xip/controller/interrupt_detect'
require 'xip/controller/dev_jumps'
require 'xip/controller/nlp'
require 'xip/controller/controller'
require 'xip/flow/base'
require 'xip/services/base_client'

if defined?(ActiveRecord)
  require 'xip/migrations/configurator'
  require 'xip/migrations/generators'
  require 'xip/migrations/railtie_config'
  require 'xip/migrations/tasks'
end
