module Ariel   

  require 'enumerator'
  
  # A TokenStream instance stores a stream of Tokens once it has used its tokenization 
  # rules to extract them from a string. A TokenStream knows its current
  # position (TokenStream#cur_pos), which is incremented when any of the
  # Enumerable methods are used (due to the redefinition of TokenStream#each).
  # As you advance through the stream, the current token is always returned and
  # then consumed. A TokenStream also provides methods for finding patterns in a
  # given stream much like StringScanner but for an array of tokens. For rule
  # generation, a certain token can be marked as being the start point of a label.
  # Finally, a TokenStream will record whether it is in a reversed or unreversed
  # state so that when rules are applied, they are always applied from the front
  # or end of the stream as required, whether it is reversed or not.
  class TokenStream
    include Enumerable
    attr_accessor :tokens, :cur_pos, :label_index, :original_text

    TOKEN_REGEXEN = [
      Wildcards.list[:html_tag], # Match html tags that don't have attributes
      /\d+/, # Match any numbers, probably good to make a split
      /\b\w+\b/, # Pick up words, will split at punctuation
      /\S/ # Grab any characters left over that aren't whitespace
      ]
    LABEL_TAG_REGEXEN = [LabelUtils.any_label_regex]
    
    def initialize()
      @tokens=[]
      @cur_pos=0
      @original_text = ""
      @reversed=false
      @contains_label_tags=false
    end

    # The tokenizer operates on a string by splitting it at every point it
    # finds a match to a regular expression. Each match is added as a token, and
    # the strings between each match are stored along with their original
    # offsets. The same is then done with the next regular expression on each of
    # these split strings, and new tokens are created with the correct offset in
    # the original text. Any characters left unmatched by any of the regular
    # expressions in TokenStream::TOKEN_REGEXEN are discarded. This approach allows a
    # hierarchy of regular expressions to work simply and easily. A simple
    # regular expression to match html tags might operate first, and then later
    # expressions that pick up runs of word characters can operate on what's
    # left. If contains_labels is set to true when calling tokenize, the
    # tokenizer will first remove and discard any occurences of label_tags (as
    # defined by the Regex set in LabelUtils) before matching and adding tokens.
    # Any label_tag tokens will be marked as such upon creation.
    def tokenize(input, contains_label_tags=false)
      string_array=[[input, 0]]
      @original_text = input
      @contains_label_tags=contains_label_tags
      LABEL_TAG_REGEXEN.each {|regex| split_string_array_by_regex(string_array, regex, false)} if contains_label_tags
      TOKEN_REGEXEN.each {|regex| split_string_array_by_regex(string_array, regex)}
      @tokens.sort!
      @tokens.size
    end

    # Note, token.cache_hash!=token.reverse.reverse.cache_hash. 
    def cache_hash
      [@tokens, @reversed].hash
    end

    def contains_label_tags?
      @contains_label_tags
    end

    # Goes through all stored Token instances, removing them if
    # Token#is_label_tag? Called after a labeled document has been extracted to
    # a tree ready for the rule learning process.
    def remove_label_tags
      @tokens.delete_if {|token| token.is_label_tag?}
    end

    # Returns the slice of the current instance containing all the tokens
    # between the token where the start_loc == the left parameter and the token
    # where the end_loc == the right parameter.
    def slice_by_string_pos(left, right)
      l_index=nil
      r_index=nil
      @tokens.each_index {|i| l_index = i if @tokens[i].start_loc == left}
      @tokens.each_index {|i| r_index = i if @tokens[i].end_loc == right}
      if l_index.nil? or r_index.nil?
        raise ArgumentError, "Cannot slice between those locations"
      else
        return slice_by_token_index(l_index, r_index)
      end
    end

    # Slices tokens between the l_index and the r_index inclusive.
    def slice_by_token_index(l_index, r_index)
      sliced = self.dup
      sliced.tokens=@tokens[l_index..r_index]
      return sliced
    end

    # Used to ensure operations such as @tokens.reverse! in one instance won't
    # inadvertently effect another.
    def deep_clone
      Marshal::load(Marshal.dump(self))
    end

    # Set a label at a given offset in the original text. Searches for a token
    # with a start_loc equal to the position passed as an argument, and raises
    # an error if one is not found.
    def set_label_at(pos)
      token_pos=nil
      @tokens.each_index {|i| token_pos = i if @tokens[i].start_loc == pos}
      if token_pos.nil?
        raise ArgumentError, "Given string position does not match the start of any token"
      else
        @label_index = token_pos
        Log.debug "Token ##{label_index} - \"#{@tokens[label_index].text}\" labeled."
        return @label_index
      end
    end

    # Returns all text represented by the instance's stored tokens, stripping any
    # label tags if the stream was declared to be containing them when it was
    # initialized (this would only happen during the process of loading labeled
    # examples). See also TokenStream#raw_text
    def text(l_index=0, r_index=-1)
      out=raw_text(l_index, r_index)
      if contains_label_tags?
        LabelUtils.clean_string(out)
      else
        out
      end
    end

    # Returns all text represented by the instance's stored tokens it will not
    # strip label tags even if the stream is marked to contain them. However,
    # you should not expect to get the raw_text once any label_tags have been
    # filtered (TokenStream#remove_label_tags).
    def raw_text(l_index=0, r_index=-1)
      return "" if @tokens.size==0
      if reversed?
        l_index, r_index = r_index, l_index
      end
      @original_text[@tokens[l_index].start_loc...@tokens[r_index].end_loc]
    end
    
    # Returns the current Token and consumes it.
		def advance
      return nil if @cur_pos > @tokens.size
      while true
        @cur_pos+=1
        current_token = @tokens[@cur_pos-1]
        return nil if current_token.nil?
        return current_token
      end
    end
    
    # Return to the beginning of the TokenStream.
    def rewind
      @cur_pos=0
      self
    end

    # Returns a copy of the current instance with a reversed set of tokens. If
    # it is set, the label_index is adjusted accordingly to point to the correct
    # token.
    def reverse
      self.deep_clone.reverse!
    end

    # Converts the given position so it points to the same token once the stream
    # is reversed. Result invalid for when @tokens.size==0
    def reverse_pos(pos)
      @tokens.size-(pos + 1)
    end

    # Same as LabeledStream#reverse, but changes are made in place.
    def reverse!
      @tokens.reverse!
      if label_index
        @label_index = reverse_pos(@label_index)
      end
      @reversed=!@reversed
      return self
    end

    # Returns true or false depending on whether the given tokenstream is in a
    # reversed state
    def reversed?
      @reversed
    end

    # Returns the number of tokens in the TokenStream
    def size
      @tokens.size
    end
    
    # Takes a list of Strings and Symbols as its arguments representing text to be matched in
    # individual tokens and Wildcards. For a match to be a
    # success, all wildcards and strings must match a consecutive sequence
    # of Tokens in the TokenStream. All matched Tokens are consumed, and the
    # TokenStream's current position is returned on success. On failure, the
    # TokenStream is returned to its original state and returns nil.
    def skip_to(*features)
      original_pos=@cur_pos
      self.each_cons(features.size) do |tokens|
        i=0
        return @cur_pos if tokens.all? {|token| i+=1; token.matches?(features[i-1])}
      end
      @cur_pos=original_pos #No match, return TokenStream to original state
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
      @tokens[@cur_pos]
    end

    private

    # Uses split_by_regex to split each member of a given array of string and
    # offset pairs in to new arrays of string and offset pairs.
    def split_string_array_by_regex(string_array, regex, add_matches=true)
      new_string_array = []
      string_array.each do |arr| 
        result = split_by_regex(arr[0], arr[1], regex, add_matches)
        new_string_array.concat result
      end
      string_array.replace new_string_array
    end

    # For tokenization, removes regex matches and creates new strings to
    # represent the gaps between each match.
    def split_by_regex(string, offset, regex, add_matches=true)
      split_points=[0]
      string_holder = []
      string.scan(regex) do |s|
        match = Regexp.last_match
        split_points << match.begin(0)
        split_points << match.end(0)
        @tokens << Token.new(match[0], match.begin(0)+offset, match.end(0)+offset, !add_matches)
      end
      split_points << string.size
      split_points.each_slice(2) do |s_pos, e_pos|
        split_string = string[s_pos...e_pos]
        string_holder << [split_string, s_pos+offset] unless split_string.empty?
      end
      return string_holder
    end
  end
end
