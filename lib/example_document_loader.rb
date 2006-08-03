module Ariel
  
  # Provides methods that read an example document, using a StructureNode tree
  # to populate a tree of Nodes with each labeled example.
  # TODO: Fix the UTF issues this implementation is bound to create. 
  class ExampleDocumentLoader

    # Assumes it is passed a root parent
    def self.load_labeled_example(file, structure, loaded_example_hash)
      raise ArgumentError, "Passed structure is not root parent" if structure.parent
      string = file.respond_to?(:read) ? file.read : file
      tokenstream = TokenStream.new
      tokenstream.tokenize(string, true)
      root = ExtractedNode.new(tokenstream, :name=>:root, :structure=>structure)
      structure.each_descendant(true) do |structure_node|
        structure_node.meta.start_rule= Proc.new do |t_stream, s_node| 
          t_stream.rewind
          LabelUtils.skip_to_label_tag(t_stream, s_node, :open)
        end
        structure_node.meta.end_rule= Proc.new do |t_stream, s_node|
          t_stream.rewind
          result = LabelUtils.skip_to_label_tag(t_stream.reverse!, s_node, :closed)
          t_stream.reverse!
          (t_stream.size-(result + 1))
        end
      end
      structure.apply_extraction_tree_on root
      root.each_descendant(true) do |extracted_node|
        if extracted_node.parent
          loaded_example_hash[extracted_node.meta.structure] << extracted_node
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
        structure_node.meta.start_rule = learner.learn_rule
        learner = Learner.new(*end_examples)
        structure_node.meta.end_rule = learner.learn_rule
      end
    end

    def self.load_directory(dir, structure)
      loaded_example_hash = Hash.new {|h, k| h[k]=[]}
      Dir.glob("#{dir}/*") do |doc|
        next if doc=~ /structure\.rb\z/
        File.open(doc) do |file|
          self.load_labeled_example(file, root, loaded_example_hash)
        end
      end
      self.supervise_learning root, loaded_example_hash
      return root
    end


  end
end
