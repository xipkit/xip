# frozen_string_literal: true

module Xip
  module Migrations
    class RailtieConfig < Rails::Application
      config.generators.options[:rails] = { orm: :active_record }

      config.generators.options[:active_record] = {
        :migration => true,
        :timestamps => true
      }
    end
  end
end
