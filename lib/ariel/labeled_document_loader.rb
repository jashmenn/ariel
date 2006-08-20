module Ariel
  
  # Provides methods that read an example document, using a Node::Structure tree
  # to populate a tree of Nodes with each labeled example.
  class LabeledDocumentLoader

    class << self

      # As its first argument it takes a root Node::Structure to which any
      # learnt rules will be added. The following arguments are strings
      # containing labeled examples for members of the passed Node::Structure
      # tree. Ariel#learn is the preferred interface for rule-learning - this
      # one may change.
      def supervise_learning(structure, *labeled_strings)
        raise ArgumentError, "No labeled strings were given" if labeled_strings.size==0
        loaded_example_hash=process_labeled_strings(structure, *labeled_strings)
        loaded_example_hash.each_pair do |structure_node, example_nodes| 
          if structure_node.node_type==:list_item
            exhaustive=true
          else
            exhaustive=false
          end
          examples = collect_labeled_tokenstreams(example_nodes, :start)
          Log.info "Learning #{"exhaustive " if exhaustive}rules for node #{structure_node.node_name} with #{example_nodes.size} examples"
          learner = Learner.new(*examples)
          start_rules = learner.learn_rule :forward, exhaustive
          Log.info "Learnt start rules #{start_rules.inspect}"
          examples = collect_labeled_tokenstreams(example_nodes, :end)
          learner = Learner.new(*examples)
          end_rules = learner.learn_rule :back, exhaustive
          Log.info "Learnt end rules, #{end_rules.inspect}"
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
            if extracted_node.parent
              loaded_example_hash[extracted_node.structure_node] << extracted_node
            end
            extracted_node.tokenstream.remove_label_tags
          end
        end
        return loaded_example_hash
      end

			# Given an array of example nodes, will return an array of tokenstreams
      # labeled for learning, at either the start or end. The example node
      # passed are actually the nodes to be extracted. This method then looks up
      # the parent, and labels their position in the parent so rules to extract
      # the given node can be learnt. Type is either :start or :end
			def collect_labeled_tokenstreams(example_nodes, type)
        example_nodes.collect do |node|
          tokenstream=node.parent.tokenstream #Rules are based on extracting from the parent
          if type==:start
            tokenstream.set_label_at(node.tokenstream.tokens.first.start_loc)
          elsif type==:end
            tokenstream.set_label_at(node.tokenstream.tokens.last.start_loc)
          end
          tokenstream
        end
      end
    end
  end
end
