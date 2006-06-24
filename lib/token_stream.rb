module Ariel   
  # A TokenStream is an Array subclass designed to handle the generation and
  # management of a collection of Token objects. A TokenStream knows its current
  # position (TokenStream#cur_pos), which is incremented when using any of the
  # iteration functions from the Enumerable mixin due to the definition of TokenStream#each.
  # As you advance through the stream, the current token is always returned and
  # then consumed.
  class TokenStream < Array
    attr_accessor :cur_pos
    # Should be suitable for most standard extraction tasks, but you may (for
    # instance) be dealing with a document where whitespace is semantically
    # significant, so it may be useful to consider tabs or multiple spaces as
    # tokens.
    DEFAULT_RE=/<\/?\w+>|\w+|[^\w\s]+/ #Don't use POSIX Regexp classes, they may not like UTF chars.
    

    def initialize()
      super()
      self.cur_pos=0
    end

    # Uses either DEFAULT_RE or your own custom regular expression to split
    # an input document in to individual Tokens, and store them in the
    # TokenStream object. The stream_offset parameter allows you to specify an
    # an offset for the location in the original document from which your input
    # starts (so that each Token's start_loc and end_loc will be correct). This
    # may be useful when loading in chunks, or only a portion of a larger
    # document is tokenised.
    def tokenize(input, stream_offset=nil, regex=DEFAULT_RE)
      unless stream_offset  #This handles the case where a TokenStream is built in chunks
        if self.empty?
          stream_offset=0
        else
          stream_offset=self.last.end_loc
        end
      end
      matches=[]
      input.scan(regex) { matches << Regexp.last_match } #This is unfortunate. Without RCR 276 I'm not sure what else to do.
      matches.each do |match| 
        text, start_loc, end_loc = match[0], match.offset(0)[0], match.offset(0)[1]
        self << Token.new(text, start_loc+stream_offset, end_loc+stream_offset)
      end
      return matches.length
    end
    
    # Returns the current Token and consumes it.
		def advance
      self.cur_pos+=1
      self[self.cur_pos-1]
    end
    
    # Return to the beginning of the TokenStream.
    def rewind
      self.cur_pos=0
    end
    
    # Accepts an array of Strings representing text to be matched in
    # individual tokens and Symbols representing Wildcards. For a match to be a
    # success, all wildcards and strings must be match on a consecutive sequence
    # of Tokens in the TokenStream. All matched Tokens are consumed, and the
    # TokenStream's current position is returned on success. On failure, the
    # TokenStream is returned to its original state and returns nil.
    def skip_to(*landmark_group)
      original_pos=self.cur_pos
      if self.any? {|token| token.matches?(landmark_group.first)}  #Search for first landmark
        self.cur_pos-=1
        if landmark_group.all? {|landmark| self.advance.matches?(landmark)}
          return self.cur_pos
        end
      end
      self.cur_pos=original_pos #No match, return TokenStream to original state
      return nil 
    end
    
    # Iterates over and consumes every Token from the cur_pos.
    def each
      while (token = self.advance)
        yield token
      end
    end

    # Returns the current Token.
    def current_token
      self[self.cur_pos]
    end

    # A rule takes the form of an Array of Arrays of landmark string/wildcards
    # for now. e.g. [[landmark1], [landmark2, landmark3]]. Rule is always
    # applied from the beginning of the TokenStream, and the TokenStream's
    # position is not remembered. Returns the stream's current position if the
    # rule matches, and nil if it fails.
    def apply_rule(rule)
      self.rewind #rules are applied from the beginning of the stream
      return cur_pos if rule.nil?
      rule.each do |landmark|
        return nil unless skip_to(*landmark)
      end
      return cur_pos
    end
  end
end
