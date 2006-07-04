module Ariel  

  # Tokens populate a TokenStream. They know their position in the original
  # document, can list the wildcards that match them and determine whether a
  # given string or wildcard is a valid match.
  class Token
  attr_reader :text, :start_loc, :end_loc
    
    # Each new Token must have a string representing its content, its start position in the
    # original document (start_loc) and the point at which it ends (end_loc).
    # For instance, in the String "This is an example", if "is" were to be made a
    # Token it would be given a start_loc of 5 and and end_loc of 7.
    def initialize(text, start_loc, end_loc)
      @text=text.to_s
      @start_loc=start_loc
      @end_loc=end_loc
    end
    
    # Tokens are only equal if they have an equal start_loc, end_loc and text.
    def ==(t)
      return (@start_loc==t.start_loc && @end_loc==t.end_loc && @text==t.text)
    end
      
    # Accepts either a string or symbol representing a wildcard in
    # Wildcards#list. Returns true if the whole Token is consumed by the wildcard or the
    # string is equal to Token#text, and false if the match fails. Raises an
    # error if the passed symbol is not a member of Wildcards#list.
    def matches?(landmark)
      if landmark.kind_of? Symbol
        raise ArgumentError, "#{landmark} is not a valid wildcard." unless Wildcards.list.has_key? landmark
        md = Wildcards.list[landmark].match(self.text)
        return false if md.nil?
        return true if md[0] == self.text  #Regex must match the whole token
      else
        return true if landmark==self.text
      end
      return false
    end

    # Returns an array of symbols corresponding to the Wildcards that match the
    # Token.
    def matching_wildcards
      return Wildcards.matching(self.text)
    end
  end
end
