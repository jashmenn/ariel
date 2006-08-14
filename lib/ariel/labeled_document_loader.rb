module Ariel
  
  # Provides methods that read an example document, using a Node::Structure tree
  # to populate a tree of Nodes with each labeled example.
  # TODO: Fix the UTF issues this implementation is bound to create. 
  class LabeledDocumentLoader

    class << self

      def supervise_learning(structure, *labeled_strings)
        raise ArgumentError, "No labeled strings were given" if labeled_strings.size==0
        loaded_example_hash=process_labeled_strings(structure, *labeled_strings)
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
          if structure_node.node_type==:list
            breakpoint "list type"
            exhaustive=true
          else
            breakpoint "non list"
            exhaustive=false
          end
          learner = Learner.new(*start_examples)
          start_rules = learner.learn_rule :forward, exhaustive
          learner = Learner.new(*end_examples)
          end_rules = learner.learn_rule :back, exhaustive
          structure_node.ruleset=RuleSet.new(start_rules, end_rules)
        end
        return structure
      end

      private
      # Processes the given labeled strings by creating a Node::Extracted tree.
      # A hash is returned with each child of the passed Node::Structure as a key,
      # and an array of the relevant extracted examples (as Node::Extracted
      # objects).
      def process_labeled_strings(structure, *labeled_strings)
        loaded_example_hash = Hash.new {|h, k| h[k]=[]}
        labeled_strings.each do |string|
          tokenstream = TokenStream.new
          tokenstream.tokenize(string, true)
          root = Node::Extracted.new(:root, tokenstream, structure)
          structure.apply_extraction_tree_on(root, true)
          root.each_descendant(true) do |extracted_node|
            p extracted_node.node_name
            if extracted_node.parent
              loaded_example_hash[extracted_node.structure_node] << extracted_node
            end
            extracted_node.tokenstream.remove_label_tags
          end
        end
        return loaded_example_hash
      end
    end
  end
end
