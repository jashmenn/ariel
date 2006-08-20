module Ariel

  # A set of methods for use when dealing with strings from labeled documents.
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

    # Helper function that returns a regex that will match any open or closing
    # label tags.
    def self.any_label_regex()
      Regexp.union(*self.label_regex)
    end

    # Removes all labels such as <l:title> from the given string and returns the
    # result.
    def self.clean_string(string)
      string.gsub self.any_label_regex, ''
    end

    # Extracts the labeled region representing the given structure node from the
    # parent_extracted_node. A new Node::Extracted is returned to be added as a
    # child to the parent_extracted_node. Used when loading labeled documents.
    def self.extract_labeled_region(structure, parent_extracted_node)
      tokenstream=parent_extracted_node.tokenstream
      start_idxs=[]
      end_idxs=[]
      tokenstream.rewind
      while start_idx = self.skip_to_label_tag(tokenstream, structure.node_name, :open)
        start_idxs << start_idx
        break unless structure.node_type==:list_item
      end
      tokenstream.rewind
      while end_idx=self.skip_to_label_tag(tokenstream, structure.node_name, :closed)
        end_idxs << (end_idx -2) #rewind to token before the label tag token
        break unless structure.node_type==:list_item
      end
      result=[]
      i=0
      start_idxs.zip(end_idxs) do |start_idx, end_idx|
        if start_idx && end_idx && (start_idx <= end_idx)
          newstream=tokenstream.slice_by_token_index(start_idx, end_idx)
          if structure.node_type==:list_item
            new_name="#{structure.node_name}_#{i}"
            i+=1
          else
            new_name = structure.node_name
          end
          child_node = Node::Extracted.new(new_name, newstream, structure)
          result << child_node
          parent_extracted_node.add_child child_node
          yield child_node if block_given?
        else
          break
        end
      end
      return result
    end

    private
    # Locates a given label tag in a tokenstream
    def self.skip_to_label_tag(tokenstream, name, type)
      case type
      when :open
        re_index=0
      when :closed
        re_index=1
      end
      regex = self.label_regex(name.to_s)[re_index]
      Log.debug "Seeking #{name.to_s} of type #{type}"
      nesting_level=0
      tokenstream.each do |token|
        if token.matches?(regex) && nesting_level==0
          Log.debug "Found a match"
          return tokenstream.cur_pos
        end
        if token.matches?(self.label_regex[0])
          # Don't increase nesting if encounter the unnested start tag that
          # pairs with the end tag we're searching for.
          nesting_level+=1 unless nesting_level==0 && token.matches?(self.label_regex(name.to_s)[0])
          Log.debug "Encountered token \"#{token.text}\", nesting level=#{nesting_level}"
        elsif token.matches?(self.label_regex[1])
          nesting_level-=1 unless nesting_level==0 && token.matches?(self.label_regex(name.to_s)[1])
          Log.debug "Encountered token \"#{token.text}\", nesting level=#{nesting_level}"
        end
      end
      return nil
    end
  end
end
