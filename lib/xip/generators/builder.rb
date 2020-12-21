# coding: utf-8
# frozen_string_literal: true

require 'thor/group'

module Xip
  module Generators
    class Builder < Thor::Group
      include Thor::Actions

      argument :name

      def self.source_root
        File.dirname(__FILE__) + "/builder"
      end

      def create_bot_directory
        empty_directory(name)
      end

      def create_bot_structure
        directory('bot', "#{name}/bot")
        directory('config', "#{name}/config")
        directory('db', "#{name}/db")

        # Miscellaneous Files
        copy_file "config.ru", "#{name}/config.ru"
        copy_file "Rakefile", "#{name}/Rakefile"
        copy_file "Gemfile", "#{name}/Gemfile"
        copy_file "README.md", "#{name}/README.md"
        copy_file "Procfile.dev", "#{name}/Procfile.dev"
        copy_file ".gitignore", "#{name}/.gitignore"
      end

      def change_directory_bundle
        puts run("cd #{name} && bundle install")
      end

    end
  end
end
