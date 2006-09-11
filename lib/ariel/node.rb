module Ariel

  # A generic Node object. As an end user, you have no need to use this. All
  # children are stored in a hash. #id and #type are undefined so they can be
  # used freely as part of a Node::Structure
  class Node
    removed_methods=[:id, :type]
    removed_methods.each {|meth| undef_method meth}
    attr_accessor :parent, :children, :node_name

    # If the name is a string, it's converted to a symbol. If not it's just
    # stored as is.
    def initialize(name)
      @children={}
      if name.kind_of? String
				@node_name=name.to_sym
			else
				@node_name=name
			end
    end

    # Given a Node object and a name, adds a child to the array of children,
    # setting its parent as the current node, as well as creating an accessor
    # method matching that name.
    def add_child(node) 
      @children[node.node_name]=node
      node.parent = self
      # Trick stolen from OpenStruct
      meta = class << self; self; end
      meta.send(:define_method, node.node_name.to_s.to_sym) {@children[node.node_name]}
    end

    # Yields each descendant node. If passed true will also yield itself.
    def each_descendant(include_self=false)
      if include_self
        node_queue=[self]
      else
        node_queue=self.children.values
      end
      until node_queue.empty? do
        node_queue.concat node_queue.first.children.values
        yield node_queue.shift
      end
    end

    def each_level(include_self=false)
      if include_self
        node_queue=[self]
      else
        node_queue=self.children.values
      end
      yield node_queue
      while node_queue.any? {|node| node.children.empty? == false} do
        # Never replace the next line with node_queue.collect!, it will modify
        # the returned array directly and that's evil
        node_queue = node_queue.collect {|node| node.children.values}
        node_queue.flatten!
        yield node_queue
      end
    end


    def inspect
      ["#{self.class.name} - node_name=#{self.node_name.inspect};",
			 "parent=#{self.parent ? self.parent.node_name.inspect : nil.inspect };",
  		 "children=#{self.children.keys.inspect};"].join ' '
    end
  end
end
