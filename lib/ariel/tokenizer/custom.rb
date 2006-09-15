module Ariel::Tokenizer

  require 'enumerator'

  class Custom
    attr_accessor :re_labels, :re_wanted, :re_unwanted

    # Takes an array of regex for the wanted tokens, and array of regex for 
    # the form that labeled tokens will take, and an array of regex for 
    # unwanted tokens.
    def initialize(re_wanted=[], re_labels=[], re_unwanted=[])
      @re_wanted=re_wanted
      @re_labels=re_labels
      @re_unwanted=re_unwanted
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
      @tokens=[]
      string_array=[[input, 0]]
      @re_labels.each {|regex| split_string_array_by_regex(string_array, regex, true)} if contains_label_tags
      @re_unwanted.each {|regex| split_string_array_by_regex(string_array, regex, false, true)}
      @re_wanted.each {|regex| split_string_array_by_regex(string_array, regex)}
      @tokens.sort!
      return @tokens
    end

    private

    # Uses split_by_regex to split each member of a given array of string and 
    # offset pairs in to new arrays of string and offset pairs.
    def split_string_array_by_regex(string_array, regex, contains_labels=false, ignore_tokens=false)
      new_string_array = []
      string_array.each do |arr| 
        result = split_by_regex(arr[0], arr[1], regex, contains_labels)
        new_string_array.concat result
      end
      string_array.replace new_string_array
    end

    # For tokenization, removes regex matches and creates new strings to
    # represent the gaps between each match.
    def split_by_regex(string, offset, regex, contains_labels=false, ignore_tokens=false)
      split_points=[0]
      string_holder = []
      string.scan(regex) do |s|
        match = Regexp.last_match
        split_points << match.begin(0)
        split_points << match.end(0)
        unless ignore_tokens
          @tokens << Ariel::Token.new(match[0], match.begin(0)+offset, match.end(0)+offset, contains_labels)
        end
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
