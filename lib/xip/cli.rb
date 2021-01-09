# frozen_string_literal: true

require 'thor'
require 'xip/cli_base'
require 'xip/commands/console'
require 'xip/commands/listen'
require 'xip/generators/builder'
require 'xip/generators/generate'

module Xip
  class Cli < Thor
    extend CliBase

    desc 'new', 'Creates a new Xip bot'
    long_desc <<-EOS
    `xip new <name>` creates a new Xip both with the given name.

    $ > xip new new_bot
    EOS
    def new(name)
      Xip::Generators::Builder.start([name])
    end


    desc 'generate', 'Generates scaffold Xip files'
    long_desc <<-EOS
    `xip generate <generator> <name>` generates scaffold Xip files

    $ > xip generate flow quote
    EOS
    def generate(generator, name)
      case generator
      when 'migration'
        Xip::Migrations::Generator.migration(name)
      when 'flow'
        Xip::Generators::Generate.start([generator, name])
      else
        puts "Could not find generator '#{generator}'."
        puts "Run `xip help generate` for more options."
      end
    end
    map 'g' => 'generate'


    desc 'version', 'Prints xip version'
    long_desc <<-EOS
    `xip version` prints the version of the bundled xip gem.
    EOS
    def version
      require 'xip/version'
      puts "#{ Xip::VERSION }"
    end
    map %w{--version -v} => :version


    desc 'server', 'Starts a xip server'
    long_desc <<-EOS
    `xip server` starts a server for the current xip project.

    $ > xip server

    $ > xip server -p 4500
    EOS
    method_option :port, aliases: '-p', desc: 'The port to run the server on'
    method_option :help, desc: 'Displays the usage message'
    def server
      if options[:help]
        invoke :help, ['server']
      else
        require 'xip/commands/server'
        Xip::Commands::Server.new(port: options.fetch(:port) { 5000 }).start
      end
    end
    map 's' => 'server'


    desc 'console', 'Starts a xip console'
    long_desc <<-EOS
    `xip console` starts the interactive xip console.

    $ > xip console --engine=pry
    EOS
    method_option :engine, desc: "Choose a specific console engine: (#{Xip::Commands::Console::ENGINES.keys.join('/')})"
    method_option :help, desc: 'Displays the usage method'
    def console
      if options[:help]
        invoke :help, ['console']
      else
        Xip::Commands::Console.new(options).start
      end
    end
    map 'c' => 'console'


    desc 'console', 'Starts a xip tunnel'
    long_desc <<-EOS
    `xip listen` starts the xip tunnel.

    $ > xip listen
    EOS
    def listen
      if options[:help]
        invoke :help, ['listen']
      else
        Xip::Commands::Listen.new(options).start
      end
    end
    map 'l' => 'listen'


    desc 'setup', 'Runs setup tasks for a specified service'
    long_desc <<-EOS
    `xip setup <service>` runs setup tasks for the specified service.

    $ > xip setup facebook
    EOS
    def setup(service)
      Xip.load_environment
      service_setup_klass = "Xip::Services::#{service.classify}::Setup".constantize
      service_setup_klass.trigger
    end


    desc 'sessions:clear', 'Clears all sessions in development'
    long_desc <<-EOS
    `xip sessions:clear` clears all sessions from Redis in development.

    $ > xip sessions:clear
    EOS
    define_method 'sessions:clear' do
      Xip.load_environment
      $redis.flushdb if Xip.env.development?
    end


    desc 'db:create', 'Creates the database from DATABASE_URL or config/database.yml for the current XIP_ENV'
    long_desc <<-EOS
    `xip db:create` Creates the database from DATABASE_URL or config/database.yml for the current XIP_ENV (use db:create:all to create all databases in the config). Without XIP_ENV or when XIP_ENV is development, it defaults to creating the development and test databases.

    $ > xip db:create
    EOS
    define_method 'db:create' do
      Kernel.exec('bundle exec rake db:create')
    end


    desc 'db:create:all', 'Creates all databases from DATABASE_URL or config/database.yml'
    long_desc <<-EOS
    `xip db:create:all` Creates all databases from DATABASE_URL or config/database.yml regardless of the enviornment specified in XIP_ENV

    $ > xip db:create:all
    EOS
    define_method 'db:create:all' do
      Kernel.exec('bundle exec rake db:create:all')
    end


    desc 'db:drop', 'Drops the database from DATABASE_URL or config/database.yml for the current XIP_ENV'
    long_desc <<-EOS
    `xip db:drop` Drops the database from DATABASE_URL or config/database.yml for the current XIP_ENV (use db:drop:all to drop all databases in the config). Without XIP_ENV or when XIP_ENV is development, it defaults to dropping the development and test databases.

    $ > xip db:drop
    EOS
    define_method 'db:drop' do
      Kernel.exec('bundle exec rake db:drop')
    end


    desc 'db:drop:all', 'Drops all databases from DATABASE_URL or config/database.yml'
    long_desc <<-EOS
    `xip db:drop:all` Drops all databases from DATABASE_URL or config/database.yml

    $ > xip db:drop:all
    EOS
    define_method 'db:drop:all' do
      Kernel.exec('bundle exec rake db:drop:all')
    end


    desc 'db:environment:set', 'Set the environment value for the database'
    long_desc <<-EOS
    `xip db:environment:set` Set the environment value for the database

    $ > xip db:environment:set
    EOS
    define_method 'db:environment:set' do
      Kernel.exec('bundle exec rake db:enviornment:set')
    end


    desc 'db:migrate', 'Migrate the database'
    long_desc <<-EOS
    `xip db:migrate` Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog).

    $ > xip db:migrate
    EOS
    define_method 'db:migrate' do
      Kernel.exec('bundle exec rake db:migrate')
    end


    desc 'db:rollback', 'Rolls the schema back to the previous version'
    long_desc <<-EOS
    `xip db:rollback` Rolls the schema back to the previous version (specify steps w/ STEP=n).

    $ > xip db:rollback
    EOS
    define_method 'db:rollback' do
      Kernel.exec('bundle exec rake db:rollback')
    end


    desc 'db:schema:load', 'Loads a schema.rb file into the database'
    long_desc <<-EOS
    `xip db:schema:load` Loads a schema.rb file into the database

    $ > xip db:schema:load
    EOS
    define_method 'db:schema:load' do
      Kernel.exec('bundle exec rake db:schema:load')
    end


    desc 'db:schema:dump', 'Creates a db/schema.rb file that is portable against any DB supported by Active Record'
    long_desc <<-EOS
    `xip db:schema:dump` Creates a db/schema.rb file that is portable against any DB supported by Active Record

    $ > xip db:schema:dump
    EOS
    define_method 'db:schema:dump' do
      Kernel.exec('bundle exec rake db:schema:dump')
    end


    desc 'db:seed', 'Seeds the database with data from db/seeds.rb'
    long_desc <<-EOS
    `xip db:seed` Seeds the database with data from db/seeds.rb

    $ > xip db:seed
    EOS
    define_method 'db:seed' do
      Kernel.exec('bundle exec rake db:seed')
    end


    desc 'db:version', 'Retrieves the current schema version number'
    long_desc <<-EOS
    `xip db:version` Retrieves the current schema version number

    $ > xip db:version
    EOS
    define_method 'db:version' do
      Kernel.exec('bundle exec rake db:version')
    end


    desc 'db:setup', 'Creates the database, loads the schema, and initializes with the seed data (use db:reset to also drop the database first)'
    long_desc <<-EOS
    `xip db:setup` Creates the database, loads the schema, and initializes with the seed data (use db:reset to also drop the database first)

    $ > xip db:setup
    EOS
    define_method 'db:setup' do
      Kernel.exec('bundle exec rake db:setup')
    end


    desc 'db:structure:dump', 'Dumps the database structure to db/structure.sql. Specify another file with SCHEMA=db/my_structure.sql'
    long_desc <<-EOS
    `xip db:structure:dump` Dumps the database structure to db/structure.sql. Specify another file with SCHEMA=db/my_structure.sql

    $ > xip db:structure:dump
    EOS
    define_method 'db:structure:dump' do
      Kernel.exec('bundle exec rake db:structure:dump')
    end


    desc 'db:structure:load', 'Recreates the databases from the structure.sql file'
    long_desc <<-EOS
    `xip db:structure:load` Recreates the databases from the structure.sql file

    $ > xip db:structure:load
    EOS
    define_method 'db:structure:load' do
      Kernel.exec('bundle exec rake db:structure:load')
    end

  end
end
