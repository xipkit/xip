# coding: utf-8
# frozen_string_literal: true

module Stealth
  class Errors < StandardError

    class ReplyFormatNotSupported < Errors
    end

    class ServiceImpaired < Errors
    end

    class ServiceNotRecognized < Errors
    end

    class ControllerRoutingNotImplemented < Errors
    end

    class UndefinedVariable < Errors
    end

    class RedisNotConfigured < Errors
    end

    class InvalidStateTransition < Errors
    end

  end
end