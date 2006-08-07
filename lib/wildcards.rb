module Ariel  
  # Contains all wildcards to be used in rule generation.
  class Wildcards
    private_class_method :new
    @@list = {
        :anything=>/.+/,
        :numeric=>/\d+/,
        :alpha_numeric=>/\w+/,
        :alpha=>/[[:alpha:]]+/,
        :capitalized=>/[[:upper:]]+\w+/,
        :all_caps=>/[[:upper:]]+/,
        :html_tag=>/<\/?\w+>/,
        :punctuation=>/[[:punct:]]+/
      }
    # Returns the hash of wildcard name (symbol) and regular expression pairs.
    def self.list
      @@list
    end

    # Given a string, will return an array of symbols from Wildcards::list that
    # match it.
    def self.matching(string)
      matches=[]
      @@list.each do |name, regex|
        if string[regex]==string
          yield name if block_given?
          matches << name
        end
      end
      matches
    end
  end
end
