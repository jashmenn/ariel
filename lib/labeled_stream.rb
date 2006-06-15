module Ariel
  # A LabeledStream is a specialised TokenStream which is used in rule learning.
  # One Token is labeled (label_index). The rule induction system will try to
  # generate a rule that consumes all tokens up to but not including the labeled
  # token.
  class LabeledStream < TokenStream
    attr_accessor :label_index
    
    # See TokenStream#tokenize. consume_until represents the index of the first
    # character of the label. For instance in "Extract !This! now", if "This"
    # was labeled then you would pass consume_until to 9, which is the
    # index of the T at the beginning of the label.
    def tokenize(input, consume_until=nil, stream_offset=nil, regex=DEFAULT_RE)
      token_count=0
      if consume_until
        token_count+= super(input[0...consume_until], stream_offset, regex) #Split the stream at the label to ensure it is tokenised seperately
        self.label_index=(self.size) #Next token will be the desired label
        token_count+= super(input[consume_until..-1], stream_offset, regex)
      else
        token_count+= super(input, stream_offset, regex)
      end
      token_count
    end

    # Returns the reversed LabeledStream. label_index is calculated so it still
    # refers to the same Token. Useful for generating rules that consume tokens
    # from the end of the document.
    def reverse
      return self.dup.reverse! 
    end

    # Same as LabeledStream#reverse, but changes are made in place.
    def reverse!
      super
      self.label_index = (self.size-(self.label_index + 1)) unless self.label_index.nil?
      return self
    end
  end
end
