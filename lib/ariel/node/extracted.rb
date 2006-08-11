require 'ariel/node'

module Ariel

  # Each ExtractedNode has a name, a tokenstream and a structure which points to
  # the relevant StructureNode.
  class Node::Extracted < Node
    attr_accessor :tokenstream, :structure_node

    def initialize(name, tokenstream, structure)
      super(name)
      @structure_node=structure
      @tokenstream=tokenstream
    end

    def extracted_text
      tokenstream.text
    end
  end
end
