module Ariel
  require 'ostruct'

  # Implements a Node object used to represent different fields in the document
  # tree.
  class Node < OpenStruct
    #Think about where metadata about the Node should be stored, e.g. start_loc in
    #a labeled document, start_rule, end_rule
    def initialize (hash=nil, &block)
      super(hash)
      process_block(&block)
      @meta={:start_loc=>nil, :end_loc=>nil, :start_rule=>nil, :end_rule=>nil, :text=>nil}
    end

    # Used to extend an already created Node. e.g.
    #  add_children do
    #    new_field1
    #    new_field2
    #  end
    def add_children(&block)
      process_block(&block)
    end

    def process_block(&block)
      instance_eval(&block) unless block.nil?
    end

    def method_missing(method, &block)
      self.new_ostruct_member(method)
      meth_string = method.to_s
      assign = (meth_string + "=").to_sym
      if meth_string.match /_list\z/
        newobj = ListNode.new(&block)
      else
        newobj = Node.new(&block)
      end
      self.send assign, newobj
    end


  end
end
