# frozen_string_literal: true

module Xip
  class Configuration < Hash

    def initialize(hash)
      hash.each do |k, v|
        self[k] = store(v)
      end

      self
    end

    def method_missing(method, *args)
      key = create_config_attribute(method)

      if setter?(method)
        self[key] = args.first
      else
        self[key]
      end
    end

    def set_default(key, default_value)
      if self[key.to_s] == nil
        self[key.to_s] = store(default_value)
      end
    end

    private

      def store(value)
        if value.is_a?(Hash)
          Xip::Configuration.new(value)
        else
          value
        end
      end

      def setter?(method)
        method.slice(-1, 1) == "="
      end

      def create_config_attribute(method)
        key = basic_config_attribute_from_method(method)

        key?(key.to_s) ? key.to_s : key
      end

      def basic_config_attribute_from_method(method)
        setter?(method) ? method.to_s.chop : method
      end

  end

end
