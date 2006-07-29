module Ariel
  
  module NodeLike
    attr_accessor :parent, :children, :meta

    # Given a Node object and a name, adds a child to the array of children,
    # setting its parent as the current node, as well as creating an accessor
    # method matching that name.
    def add_child(node, name)
      new_ostruct_member(name)
      assign = (name.to_s + "=").to_sym
      send assign, node
      @children.push node
      node.parent = self
      node.meta.name=name
    end


    def each_descendant
      node_queue=[self.children]
      until node_queue.empty? do
        node_queue.concat node_queue.first.children
        yield node_queue.shift
      end
    end
  end
end
