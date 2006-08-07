module Ariel
  require 'ostruct'

  # Each ExtractedNode has a name, a tokenstream and a structure which points to
  # the relevant StructureNode.
  class ExtractedNode
    include NodeLike
    attr_accessor :tokenstream

    def initialize(name, tokenstream, structure)
      super()
      @children={}
      @meta = OpenStruct.new({:name=>name, :structure=>structure})
      @tokenstream=tokenstream
    end

    def extracted_text
      tokenstream.text
    end
  end
end
