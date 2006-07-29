module Ariel
  require 'ostruct'

  # Implements a Node object used to represent the structure of the document
  # tree. Each node stores start and end rules to extract the desired content
  # from its parent node.
  class ExtractedNode < OpenStruct
    include NodeLike
    attr_accessor :tokenstream
    def initialize (tokenstream, meta_hash=nil)
      super()
      @children=[]
      @meta = OpenStruct.new(meta_hash)
      @tokenstream=tokenstream
      @meta.name=:root unless @meta.name
    end

    def extracted_text
      tokenstream.get_text
    end

    def extracted_tokens
      tokenstream.to_a
    end


  end


end
