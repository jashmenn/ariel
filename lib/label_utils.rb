module Ariel

  # A set of methods for use when dealing with strings from labeled documents
  module LabelUtils
    S_DELIMITER="<"
    E_DELIMITER=">"

    # Returns a Regexp that will locate either :open or :closing label tags. A
    # second tag_contents parameter can also be passed to locate a certain named
    # tag. By default the regex will find any correctly formatted label tags.
    # The returned regex is case insensitive.
    def self.label_regex(open_or_closed, tag_contents='\w+')
      if open_or_closed == :open
        /#{S_DELIMITER}l:#{tag_contents}#{E_DELIMITER}/i
      else
        /#{S_DELIMITER}\/l:#{tag_contents}#{E_DELIMITER}/i
      end
    end

    # Helper function that returns a regex that will return any open or closing
    # label tags.
    def self.any_label_regex()
      Regexp.union(self.label_regex(:open), self.label_regex(:closed))
    end

    # Removes all labels such as <l:title> from the given string and returns the
    # result.
    def self.clean_string(string)
      string.gsub self.any_label_regex, ''
    end

    def self.skip_to_label_tag(tokenstream, structure_node, type)
      regex = self.label_regex(type, structure_node.meta.name.to_s)
      debug "Seeking #{structure_node.meta.name.to_s} of type #{type}"
      nesting_level=0
      tokenstream.each do |token|
        if token.matches?(regex)
          return tokenstream.cur_pos if nesting_level==0
        end
        if token.matches?(self.label_regex(:open))
          nesting_level+=1
          debug "Encountered token \"#{token.text}\", nesting level=#{nesting_level}"
        elsif token.matches?(self.label_regex(:closed))
          nesting_level-=1
          debug "Encountered token \"#{token.text}\", nesting level=#{nesting_level}"
        end

      end
    end
  end
end
