# coding: utf-8
# frozen_string_literal: true

module Xip
  module Redis
    extend ActiveSupport::Concern

    included do
      private

      def get_key(key, expiration: Xip.config.session_ttl)
        if expiration > 0
          getex(key, expiration)
        else
          $redis.get(key)
        end
      end

      def delete_key(key)
        $redis.del(key)
      end

      def getex(key, expiration=Xip.config.session_ttl)
        $redis.multi do
          $redis.expire(key, expiration)
          $redis.get(key)
        end.last
      end

      def persist_key(key:, value:, expiration: Xip.config.session_ttl)
        if expiration > 0
          $redis.setex(key, expiration, value)
        else
          $redis.set(key, value)
        end
      end

    end
  end
end
