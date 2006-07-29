module Ariel
  
  # Provides methods that read an example document, using a StructureNode tree
  # to populate a tree of Nodes with each labeled example.
  # TODO: For the moment, lists must be named such as comment_list, and
  # individual items must be then labeled comment.
  # TODO: Fix the UTF issues this implementation is bound to create. 
  class ExampleDocumentLoader

    def initialize(file, structure)
      @document_text = file.read
      @structure=structure
    end

    # Given a string, extracts a label with a given name that has the form
    # <l:example>I'm an example</l:example>. Returns an array of arrays of match
    # text, match begin, match end. Only extracts labels at the top level of the
    # given string in order to allow for multiple labels of the same name at
    # different depths of the tree. It works out the match being and end offsets
    # on a string that has the labels stripped.
    # TODO delete this method
    def self.extract_label(label_name, string)
      results = []
      string.scan /#{S_DELIMITER}l:#{label_name.to_s}#{E_DELIMITER}(.*)#{S_DELIMITER}\/l:#{label_name.to_s}#{E_DELIMITER}/i do |result|
        # Only add result if opened labels in the pre-match == closed labels in the
        # pre-match
        match=Regexp.last_match
        left_string = match.pre_match+"#{S_DELIMITER}l:#{label_name.to_s}#{E_DELIMITER}"
        label_chars = left_string.size - self.clean_string(left_string).size # Number of characters in label tags
        (results << [match[1], match.begin(1) - label_chars, match.end(1) - label_chars]) if self.count_labels(match.pre_match)==self.count_labels(match.pre_match, :closing)
      end
      return nil if results.empty?
      return results
    end

    # Assumes it is passed a root parent
    def self.process_labeled_example(file, structure)
      raise ArgumentError, "Passed structure is not root parent" if structure.parent
      labeled_string = file.read
      unlabeled_string = self.clean_string(labeled_string)
      tokenstream = Ariel::LabeledStream.new
      tokenstream.tokenize(unlabeled_string)
      root = LabeledNode.new(tokenstream, :name=>:root, :label_start=>0, :label_end=>unlabeled_string.size, :structure=>structure)
      






    end
  end
end
