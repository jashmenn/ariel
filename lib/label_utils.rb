module Ariel

  # A set of methods for use when dealing with strings from labeled documents
  module LabelUtils
    S_DELIMITER="<"
    E_DELIMITER=">"

    def self.label_regex(open_or_closed, tag_contents='\w+')
      if open_or_closed == :open
        /#{S_DELIMITER}l:#{tag_contents}#{E_DELIMITER}/i
      else
        /#{S_DELIMITER}\/l:#{tag_contents}#{E_DELIMITER}/i
      end
    end

    def self.any_label_regex()
      Regexp.union(self.label_regex(:open), self.label_regex(:closed))
    end

    # Removes all labels such as <l:title> from the given string and returns the
    # result.
    def self.clean_string(string)
      string.gsub self.any_label_regex, ''
    end

    def self.count_labels(string, type=:open)
      if type == :open
        regex = self.label_regex(:open)
      else
        regex = self.label_regex(:closed)
      end
      string.scan(regex).size
    end

    def self.label_is_unnested?(string)
      return true if self.count_labels(string) == self.count_labels(string, :closing)
      return false
    end

    # Given a string, extracts a label with a given name that has the form
    # <l:example>I'm an example</l:example>. Returns an array of arrays of match
    # text, match begin, match end. Only extracts labels at the top level of the
    # given string in order to allow for multiple labels of the same name at
    # different depths of the tree. It works out the match being and end offsets
    # on a string that has the labels stripped.
    def self.extract_label(label_name, string)
      results = []
      regex =  /#{self.label_regex(:open, label_name.to_s)}(.*)#{self.label_regex(:closed, label_name.to_s)}/
      string.scan regex do |result|
        # Only add result if opened labels in the pre-match == closed labels in the
        # pre-match
        match=Regexp.last_match 
        (results << [match[1], match.begin(1), match.end(1)]) if self.label_is_unnested?(match.pre_match)
      end
      return nil if results.empty?
      return results
    end
  end
end
