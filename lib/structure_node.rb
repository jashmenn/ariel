module Ariel
  require 'ostruct'

  # Implements a Node object used to represent the structure of the document
  # tree. Each node stores start and end rules to extract the desired content
  # from its parent node. Could be viewed as a rule-storing object.
  class StructureNode
    include NodeLike
    attr_accessor :ruleset
    def initialize(name=:root, type=:not_list, &block)
      @children={}
      @meta = OpenStruct.new({:name=>name, :node_type=>type})
      yield self if block_given?
    end

    # Used to extend an already created Node. e.g.
    #  node.extend_structure do |r|
    #    r.new_field1
    #    r.new_field2
    #  end
    def extend_structure(&block)
      yield self if block_given?
    end

    # Given a Node to apply it's rules to, this function will create a new node
    # and add it as a child of the given node. For StructureNodes of :list type,
    # the list is extracted and so are each of the list items. In this case,
    # only the list items are yielded.
    def extract_from(node)
      # Will be reimplemented to return an array of extracted items
      newstream = @ruleset.apply_to(node.tokenstream)
      extracted_node = ExtractedNode.new(meta.name, newstream, self)
      node.add_child extracted_node
      
      if self.meta.node_type == :list
        #Do stuff
      end
      return extracted_node
    end

    # Applies the extraction rules stored in the current StructureNode and all its
    # descendant children.
    def apply_extraction_tree_on(root_node, extract_labels=false)
      extraction_queue = [root_node]
      until extraction_queue.empty? do
        new_parent = extraction_queue.shift
        new_parent.meta.structure.children.values.each do |child|
          if extract_labels
            extracted_node=LabelUtils.extract_label(child, new_parent)
          else
            extracted_node=child.extract_from(new_parent)
          end
          extraction_queue.push(extracted_node)
        end
      end
      return root_node
    end

    def item(name, &block)
      self.add_child(StructureNode.new(name, &block))
    end

    def list_item(name, &block)
      self.add_child(StructureNode.new(name, :list, &block))
    end


    def method_missing(method, *args, &block)
      if @children.has_key? method
        @children[method]
      else
        super
      end
    end
  end
end

