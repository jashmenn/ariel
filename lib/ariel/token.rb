module Ariel  

  # Tokens populate a TokenStream. They know their position in the original
  # document, can list the wildcards that match them and determine whether a
  # given string or wildcard is a valid match. During the process of parsing a
  # labeled document, some tokens may be marked as being a label_tag. These are
  # filtered from the TokenStream before the rule learning phase.
  class Token
  attr_reader :text, :start_loc, :end_loc
    
    # Each new Token must have a string representing its content, its start position in the
    # original document (start_loc) and the point at which it ends (end_loc).
    # For instance, in str="This is an example", if "is" were to be made a
    # Token it would be given a start_loc of 5 and and end_loc of 7, which is
    # str[5...7]
    def initialize(text, start_loc, end_loc, label_tag=false)
      @text=text.to_s
      @start_loc=start_loc
      @end_loc=end_loc
      @label_tag=label_tag
    end

    # Returns true or false depending on whether the token was marked as a label
    # tag when it was initialized.
    def is_label_tag?
      @label_tag
    end

    # Tokens are only equal if they have an equal start_loc, end_loc and text.
    def ==(t)
      return (@start_loc==t.start_loc && @end_loc==t.end_loc && @text==t.text)
    end

    # Tokens are sorted based on their start_loc
    def <=>(t)
      @start_loc <=> t.start_loc
    end
      
    # Accepts either a string a symbol representing a wildcard in
    # Wildcards#list or an an arbitrary regex. Returns true if the
    # whole Token is consumed by the wildcard or the string is equal
    # to Token#text, and false if the match fails. Raises an
    # error if the passed symbol is not a member of Wildcards#list.
    def matches?(landmark)
      if landmark.kind_of? Symbol
        landmark = Wildcards.list.fetch(landmark)
      end
      if self.text[landmark] == self.text
        return true
      else
        return false
      end
    end

    # Returns an array of symbols corresponding to the Wildcards that match the
    # Token.
    def matching_wildcards
      return Wildcards.matching(self.text)
    end

    # Redefined for caching purposes. This proved to be too slow.
#    def hash
#      [@text, @start_loc, @end_loc, @label_tag].hash
#    end
  end
end
