module Ariel  
      WILDCARDS = {
        :anything=>/.+/,
        :numeric=>/\d+/,
        :alpha_numeric=>/\w+/,
        :alpha=>/[[:alpha:]]+/,
        :capitalized=>/[[:upper:]]+\w+/,
        :all_caps=>/[[:upper:]]+/,
        :html_tag=>/<\/?\w+>/,
        :punctuation=>/[[:punct:]]+/
      }

  class Token
  attr_reader :text, :start_loc, :end_loc
    
    def initialize(text, start_loc, end_loc)
      @text=text.to_s
      @start_loc=start_loc
      @end_loc=end_loc
    end
    
    def ==(t)
      return (@start_loc==t.start_loc && @end_loc==t.end_loc && @text==t.text)
    end
      
    def matches?(landmark)
      if landmark.kind_of? Symbol
        raise ArgumentError, "#{landmark} is not a valid wildcard." unless WILDCARDS.has_key? landmark
        md = WILDCARDS[landmark].match(self.text)
        return false if md.nil?
        return true if md[0].length == self.text.length  #Regex must match the whole token
      else
        return true if landmark==self.text
      end
      return false
    end

    def matching_wildcards
      matches = Array.new
      WILDCARDS.each do |name, regex|
        (matches << name) if self.matches?(regex)
      end
      return matches
    end
  end
end
