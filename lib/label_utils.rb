module Ariel

  # A set of methods for use when dealing with strings from labeled documents
  module LabelUtils
    S_LABEL="<"
    E_LABEL=">"

    # Returns an array containing a pair of regular expressions to match a start
    # label tag and an end label tag. If the tag_contents is not modified the
    # regular expressions will return any properly formatted label tag. The
    # namespace to search for can also be modified. The returned regular
    # expressions are case insensitive.
    def self.label_regex(tag_contents='\w+', namespace='l')
      [/#{S_LABEL}#{namespace}:#{tag_contents}#{E_LABEL}/i,
      /#{S_LABEL}\/#{namespace}:#{tag_contents}#{E_LABEL}/i]
    end

    # Helper function that returns a regex that will return any open or closing
    # label tags.
    def self.any_label_regex()
      Regexp.union(*self.label_regex)
    end

    # Removes all labels such as <l:title> from the given string and returns the
    # result.
    def self.clean_string(string)
      string.gsub self.any_label_regex, ''
    end

    # Extracts the label representing the given structure node from the
    # parent_extracted_node. A new ExtractedNode is returned to be added as a
    # child to the parent_extracted_node. Used when loading labeled documents.
    def self.extract_label(structure, parent_extracted_node)
      tokenstream=parent_extracted_node.tokenstream
      start_idx=self.skip_to_label_tag(tokenstream, structure.meta.name, :open)
      end_idx=self.skip_to_label_tag(tokenstream.reverse, structure.meta.name, :closed)
      end_idx=tokenstream.reverse_pos end_idx
      newstream=tokenstream.slice_by_token_index(start_idx, end_idx)
      child_node=ExtractedNode.new(structure.meta.name, newstream, structure)
      parent_extracted_node.add_child child_node
      return child_node
    end


    # Locates a given label tag in a tokenstream
    def self.skip_to_label_tag(tokenstream, name, type)
      case type
      when :open
        re_index=0
      when :closed
        re_index=1
      end
      tokenstream.rewind
      regex = self.label_regex(name.to_s)[re_index]
      p regex
      debug "Seeking #{name.to_s} of type #{type}"
      nesting_level=0
      tokenstream.each do |token|
        if token.matches?(regex)
          return tokenstream.cur_pos if nesting_level==0
        end
        if token.matches?(self.label_regex[0])
          nesting_level+=1
          debug "Encountered token \"#{token.text}\", nesting level=#{nesting_level}"
        elsif token.matches?(self.label_regex[1])
          nesting_level-=1
          debug "Encountered token \"#{token.text}\", nesting level=#{nesting_level}"
        end
      end
    end
  end
end
