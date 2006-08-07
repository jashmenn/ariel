module Ariel
  
  module NodeLike
    attr_accessor :parent, :children, :meta

    # Given a Node object and a name, adds a child to the array of children,
    # setting its parent as the current node, as well as creating an accessor
    # method matching that name.
    def add_child(node) 
      @children[node.meta.name]=node
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
  end
end
