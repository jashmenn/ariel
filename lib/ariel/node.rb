module Ariel
 
  class Node
    removed_methods=[:id, :type]
    removed_methods.each {|meth| undef_method meth}
    attr_accessor :parent, :children, :node_name

    def initialize(name)
      @children={}
      @node_name=name.to_sym
    end

    # Given a Node object and a name, adds a child to the array of children,
    # setting its parent as the current node, as well as creating an accessor
    # method matching that name.
    def add_child(node) 
      @children[node.node_name]=node
      node.parent = self
    end

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

    def method_missing(method, *args, &block)
      if @children.has_key? method
        @children[method]
      else
        super
      end
    end
  end
end
