require 'ariel/node'

module Ariel

  # Implements a Node object used to represent the structure of the document
  # tree. Each node stores start and end rules to extract the desired content
  # from its parent node. Could be viewed as a rule-storing object.
  class Node::Structure < Node
    attr_accessor :ruleset, :node_type

    def initialize(name=:root, type=:not_list, &block)
      super(name)
      @node_type=type
      yield self if block_given?
    end

    # Used to extend an already created Node. e.g.
    #  node.extend_structure do |r|
    #    r.item :new_field1
    #    r.item :new_field2
    #  end
    def extend_structure(&block)
      yield self if block_given?
    end

    # Given a Node to apply it's rules to, this function will create a new node
    # and add it as a child of the given node. It returns an array of the items
    # extracted by the rule
    def extract_from(node)
      extractions=[]
      i=0
      return extractions if @ruleset.nil? #no extractions if no rule has been learnt
      Log.debug "Applying ruleset for node #{self.node_name.inspect}"
      @ruleset.apply_to(node.tokenstream) do |newstream|
        if self.node_type==:list_item
          new_node_name=i
          i+=1
        else
          new_node_name=@node_name
        end
        extracted_node = Node::Extracted.new(new_node_name, newstream, self)
        node.add_child extracted_node
        extractions << extracted_node
      end
      return extractions
    end

    # Applies the extraction rules stored in the current Node::Structure and all its
    # descendant children.
    def apply_extraction_tree_on(root_node, extract_labels=false)
      extraction_queue = [root_node]
      until extraction_queue.empty? do
        new_parent = extraction_queue.shift
        new_parent.structure_node.children.values.each do |child|
          if extract_labels
            extractions=LabelUtils.extract_labeled_region(child, new_parent)
          else
            extractions=child.extract_from(new_parent)
          end
          extractions.each {|extracted_node| extraction_queue.push extracted_node}
        end
      end
      return root_node
    end

    # Use when defining any object that occurs once. #list is a synonym, but
    # it's recommended you use it when defining a container for list_items. The
    # children of a list_item are just items. e.g.
    # <tt>structure = Ariel::Node::Structure.new do |r|
    #   r.list :comments do |c|  # r.item :comments would be equivalent, but less readable
    #     c.list_item :comment do |c|
    #       c.item :author  # Now these are just normal items, as they are extracted once from their parent
    #       c.item :date
    #       c.item :body
    #     end
    #   end
    # end
    def item(name, &block)
      self.add_child(Node::Structure.new(name, &block))
    end
    # Extracting a list is really the same as extracting a normal item, but
    # people probably still prefer to call a list a list.
    alias :list :item

    # See the docs for #item for a discussion of when to use #item and when to
    # use #list_item.
    def list_item(name, &block)
      self.add_child(Node::Structure.new(name, :list_item, &block))
    end
  end
end

