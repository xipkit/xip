# frozen_string_literal: true

require 'zeitwerk'

module Xip
  class Reloader

    def initialize
      @reloader = Class.new(ActiveSupport::Reloader)
      @loader = Zeitwerk::Loader.new
      # @loader.logger = method(:puts)
      @loader
    end

    def load_bot!
      load_autoload_paths!
      enable_reloading!
      enable_eager_load!
      @loader.setup
    end

    def load_autoload_paths!
      if Xip.config.autoload_paths.present?
        Xip.config.autoload_paths.each do |autoload_path|
          @loader.push_dir(autoload_path)
        end

        # Bot-specific ignores
        Xip.config.autoload_ignore_paths.each do |autoload_ignore_path|
          @loader.ignore(autoload_ignore_path)
        end

        # Ignore setup files
        @loader.ignore(File.join(Xip.root, 'config', 'initializers'))
        @loader.ignore(File.join(Xip.root, 'config', 'boot.rb'))
        @loader.ignore(File.join(Xip.root, 'config', 'environment.rb'))
        @loader.ignore(File.join(Xip.root, 'config', 'puma.rb'))
      end
    end

    def enable_eager_load!
      if Xip.config.eager_load
        @loader.eager_load
        Xip::Logger.l(topic: 'xip', message: 'Eager loading enabled.')
      end
    end

    def enable_reloading!
      if Xip.config.hot_reload
        @checker = ActiveSupport::EventedFileUpdateChecker.new([], files_to_watch) do
          reload!
        end

        @loader.enable_reloading
        Xip::Logger.l(topic: 'xip', message: 'Hot reloading enabled.')
      end
    end

    # Only reloads if a change has been detected in one of the autoload files`
    def reload
      if Xip.config.hot_reload
        @checker.execute_if_updated
      end
    end

    # Force reloads reglardless of filesystem changes
    def reload!
      if Xip.config.hot_reload
        @loader.reload
      end
    end

    def call
      @reloader.wrap do
        reload
        yield
      end
    end

    private

      def files_to_watch
        Xip.config.autoload_paths.map do |path|
          [path, 'rb']
        end.to_h
      end

  end
end
