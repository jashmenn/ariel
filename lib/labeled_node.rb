module Ariel
  require 'ostruct'

  class LabeledNode
    include NodeLike
    attr_accessor :tokenstream

    def initialize (tokenstream, meta_hash=nil)
      super()
      @children=[]
      @meta = OpenStruct.new(meta_hash)
      @tokenstream=tokenstream
      @meta.name=:root unless @meta.name
    end
  end
end
