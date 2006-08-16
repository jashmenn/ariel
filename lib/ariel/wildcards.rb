module Ariel  
  # Contains all wildcards to be used in rule generation.
  class Wildcards
    @list = {
        :anything=>/.+/,
        :numeric=>/\d+/,
        :alpha_numeric=>/\w+/,
        :alpha=>/[[:alpha:]]+/,
        :capitalized=>/[[:upper:]]+\w+/,
        :all_caps=>/[[:upper:]]+/,
        :html_tag=>/<\/?\w+>|<\w+\s+\/>/,
        :punctuation=>/[[:punct:]]+/
      }

    class << self
      private :new
      # Returns the hash of wildcard name (symbol) and regular expression pairs.
      def list
        @list
      end

      # Given a string, will return an array of symbols from Wildcards::list that
      # match it.
      def matching(string)
        matches=[]
        @list.each do |name, regex|
          if string[regex]==string
            yield name if block_given?
            matches << name
          end
        end
        matches
      end

    end
  end
end
