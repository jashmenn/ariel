module Ariel
  require 'ostruct'

  # Implements a Node object used to represent the structure of the document
  # tree. Each node stores start and end rules to extract the desired content
  # from its parent node.
  class Node < OpenStruct
    attr_accessor :parent, :children, :meta
    def initialize (meta_hash=nil)
      super()
      @meta = OpenStruct.new(meta_hash)
      @children=[]
    end

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
  end
end
