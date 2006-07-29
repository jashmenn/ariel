module Ariel
  require 'ostruct'

  # Implements a Node object used to represent the structure of the document
  # tree. Each node stores start and end rules to extract the desired content
  # from its parent node. Could be viewed as a rule-storing object.
  class StructureNode < OpenStruct
    include NodeLike
    def initialize (type=:not_list, meta_hash=nil, &block)
      super()
      @children=[]
      @meta = OpenStruct.new(meta_hash)
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

    # Given a Node to apply it's rules to, this function will create a new node
    # and add it as a child of the given node. For StructureNodes of :list type,
    # the list is extracted and so are each of the list items. In this case,
    # only the list items are yielded.
    def extract_from(node)
      start_token_pos=node.tokenstream.apply_rule(@meta.start_rule) #TODO must handle rules that don't match
      end_token_pos=node.tokenstream.apply_rule(@meta.end_rule)
      return false if (start_token_pos.nil? or end_token_pos.nil?) #Extraction failed, should an empty node be added anyway?
      newstream = node.tokenstream.slice_by_token_index(start_token_pos, end_token_pos)
      extracted_node = ExtractedNode.new(newstream, :name=>meta.name, :structure=>self)
      node.add_child extracted_node, meta.name
      yield extracted_node if block_given? and meta.node_type != :list

      if self.meta.node_type == :list
        #do list stuff
      end
    
    end

    # Applies the extraction rules stored in the current StructureNode and all its
    # descendant children.
    def apply_extraction_tree_on(root_node)
      extraction_queue = [root_node]
      until extraction_queue.empty? do
        new_parent = extraction_queue.shift
        new_parent.meta.structure.children.each do |child|
          child.extract_from(new_parent) {|node| extraction_queue.push node} #extract_from returns only those nodes that need further examination
        end
      end
    end

    def method_missing(method, &block)
      if method.to_s.match(/_list\z/)
        self.add_child(StructureNode.new(:list, &block), method)
      else
        self.add_child(StructureNode.new(&block), method)
      end
    end
  end
end

