# frozen_string_literal: true

module Xip
  module CliBase
    def define_commands(&blk)
      class_eval(&blk) if block_given?
    end

    def banner(command, nspace = true, subcommand = false)
      super(command, nspace, namespace != 'xip:cli')
    end

    def handle_argument_error(command, error, args, arity)
      name = [(namespace == 'xip:cli' ? nil : namespace), command.name].compact.join(" ")

      msg = "ERROR: \"#{basename} #{name}\" was called with "
      msg << "no arguments"               if     args.empty?
      msg << "arguments " << args.inspect unless args.empty?
      msg << "\nUsage: #{banner(command).inspect}"

      raise Thor::InvocationError, msg
    end
  end
end
