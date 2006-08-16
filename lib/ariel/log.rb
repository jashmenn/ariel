require 'singleton'

module Ariel
  
  # Very simple Log class. By default outputs to stdout and ignored messages
  # below :info level. Should probably get rid of the usage of Singleton as it's
  # used very little, with the classes eigenclass/singleton class used mostly
  # for the same purpose.
  class Log
    include Singleton

    SEVERITY={:debug=>0, :info=>1, :warn=>2, :error=>3}

    def initialize
      self.class.output_to_stdout
      if $DEBUG
        self.class.set_level :debug
      else
        self.class.set_level :info
      end
    end

    class << self  
      SEVERITY.keys.each do |level|
        define_method(level) {|message| instance; log message, level}
      end

      def set_level(level)
        if SEVERITY.has_key? level
          @log_level=level
        else
          raise ArgumentError, "Invalid log level given"
        end
      end

      def current_level
        @log_level
      end

      def output_to_stdout
        @output=:stdout
      end

      def output_to_file
        @output=:file
      end

      def log(message, level)
        if SEVERITY[@log_level] <= SEVERITY[level]
          message = "#{level}: #{message}"
          if @output==:file
            File.open('debug.log', 'ab') {|f| f.puts message }
          elsif @output==:stdout
            puts message
          end
          return message          
        end
        return nil
      end
    end
  end
end
