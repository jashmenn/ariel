module Ariel  
  
  class Wildcards
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

    def self.list
      @@list
    end

    def self.matching(string)
      matches=[]
      @@list.each do |name, regex|
        md=regex.match(string)
        if md && md[0]==string
          yield name if block_given?
          matches << name
        end
      end
      matches
    end
  end
end
