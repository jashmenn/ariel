module Ariel

  # Implements a Node object used to represent the structure of the document
  # tree. Each node stores start and end rules to extract the desired content
  # from its parent node.
  class StructureNode < Node
    def initialize (type=:not_list, meta_hash=nil, &block)
      super(meta_hash)
      @meta.node_type = type
      yield self if block_given?
    end

    # Used to extend an already created Node. e.g.
    #  node.extend do |r|
    #    r.new_field1
    #    r.new_field2
    #  end
    def extend(&block)
      yield self if block_given?
    end

    # Given a TokenStream, and a Node to extract to, this method will apply the
    # extraction rules of the StructureNode's immediate children.
    def extract_children(tokenstream, destination)
      if self.meta.node_type == :list
        #do list stuff
      end
      self.children.each do |node|
        start_token_pos=tokenstream.apply_rule(node.meta.start_rule) #must handle rules that don't match
        end_token_pos=tokenstream.apply_rule(node.meta.end_rule)
        next if (start_token_pos.nil? or end_token_pos.nil?) #Extraction failed, should an empty node be added anyway?
        extracted_tokens = tokenstream[start_token_pos..end_token_pos]
        name = node.meta.name
        text_start = tokenstream[start_token_pos].start_loc
        text_end = tokenstream[end_token_pos].end_loc
        extracted_text = tokenstream.original_text[text_start...text_end]
        extracted_node = Node.new(:name=>name)
        extracted_node.extracted_tokens = extracted_tokens
        extracted_node.extracted_text = extracted_text
        destination.new_ostruct_member name
        destination.send "#{name}=".to_sym, extracted_node
        yield node, extracted_node if block_given?
      end
      
    end

    # If self.parent.nil? (the current node is the parent of the whole tree),
    # this method will apply the extraction rules from each child node, to
    # create a tree of ExtractedNodes.
    def apply_extraction_tree_on(tokenstream)
      # This implementation won't extend to ListNodes
      raise StandardError, "Method must be called on the parent node of the tree" unless self.parent.nil?
      parent_node = Node.new
      nodes_to_extract = [[self, parent_node]]
      parent_node.extracted_tokens = tokenstream
      parent_node.extracted_text = tokenstream.original_text
      until nodes_to_extract.empty? do
        node_queue=[]
        nodes_to_extract.each do |node_dest_pair|
          node, dest = node_dest_pair
          node.extract_children(dest.extracted_tokens, dest) do |structure_node, extracted_node|
            node_queue << [structure_node, extracted_node]            
          end
        end
        nodes_to_extract = node_queue
      end
      return parent_node
      
    end

    def method_missing(method, &block)
      if method.to_s.match /_list\z/
        self.add_child(StructureNode.new(:list, &block), method)
      else
        self.add_child(StructureNode.new(&block), method)
      end
    end
  end
end

