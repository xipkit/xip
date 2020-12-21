# frozen_string_literal: true

require "rails/generators"

module Xip
  module Migrations
    class Generator
      def self.migration(name, options="")
        generator_params = [name] + options.split(" ")
        Rails::Generators.invoke("active_record:migration", generator_params,
          destination_root: Xip.root
        )
      end
    end
  end
end
