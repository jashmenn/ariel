module Ariel
  
  # Provides methods that read an example document, using a Node::Structure tree
  # to populate a tree of Nodes with each labeled example.
  # TODO: Fix the UTF issues this implementation is bound to create. 
  class ExampleDocumentLoader

    # Assumes it is passed a root parent
    def self.load_labeled_example(file, structure, loaded_example_hash)
      raise ArgumentError, "Passed structure is not root parent" if structure.parent
      string = file.respond_to?(:read) ? file.read : file
      tokenstream = TokenStream.new
      tokenstream.tokenize(string, true)
      root = Node::Extracted.new(:root, tokenstream, structure)
      structure.apply_extraction_tree_on(root, true)
      root.each_descendant(true) do |extracted_node|
        if extracted_node.parent
          loaded_example_hash[extracted_node.structure_node] << extracted_node
        end
        extracted_node.tokenstream.remove_label_tags
      end
      return loaded_example_hash
    end

    def self.supervise_learning(structure, loaded_example_hash)
      loaded_example_hash.each_pair do |structure_node, example_nodes|
        start_examples=[]
        end_examples=[]
        example_nodes.each do |node|
          start_tstream=node.parent.tokenstream #Rules are based on extracting from the parent
          start_tstream.set_label_at(node.tokenstream.tokens.first.start_loc)
          start_examples << start_tstream
          end_tstream=node.parent.tokenstream.reverse
          end_tstream.set_label_at(node.tokenstream.tokens.last.start_loc)
          end_examples << end_tstream
        end
        learner = Learner.new(*start_examples)
        start_rules = learner.learn_rule :forward
        learner = Learner.new(*end_examples)
        end_rules = learner.learn_rule :back
        structure_node.ruleset=RuleSet.new(start_rules, end_rules)
      end
    end

    def self.load_directory(dir, structure)
      loaded_example_hash = Hash.new {|h, k| h[k]=[]}
      Dir.glob("#{dir}/*") do |doc|
        next if doc=~ /structure\.rb\z/
        File.open(doc) do |file|
          self.load_labeled_example(file, structure, loaded_example_hash)
        end
      end
      self.supervise_learning structure, loaded_example_hash
      return structure
    end


  end
end
