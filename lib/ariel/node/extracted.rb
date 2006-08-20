require 'ariel/node'

module Ariel

  # Each Node::Extracted has a name, a TokenStream and a structure which points to
  # the relevant Node::Structure. Skip straight to #search, #/ and #at for the
  # query interface. This is strongly recommended over using the built in method
  # accessors (a method isn't defined if a given field isn't extracted, so
  # you're going to have to catch a lot of potential errors).
  class Node::Extracted < Node
    attr_accessor :tokenstream, :structure_node

    def initialize(name, tokenstream, structure)
      super(name)
      @structure_node=structure
      @tokenstream=tokenstream
    end

    # Returns the text contained in the TokenStream.
    def extracted_text
      tokenstream.text
    end

    # Index based accessor for the Node::Extracted's children. Supports Range objects.
		# Aims to provide behaviour that makes sense, especially when a Node has
    # list children. Node::Extracted#[0..0] will return an array, while
    # Node::Extracted[0] will not. This behaviour is the same as Ruby's standard
    # Array class.
    def [](*args)
			dont_splat=false #determines whether to splat or not if there is only a single result
			args.collect! do |arg|
				if arg.kind_of? Range
					arg=arg.to_a
					dont_splat=true
				end
				arg
			end
			args.flatten!
      dont_splat=true if args.size > 1
      result=@children.values_at(*args).compact
			if result.size==1 && dont_splat==true
				return result
			else
				return *result
			end
    end

    # The preferred way of querying extracted information. If nothing was
    # extracted, an empty array is returned. This is much safer than using
    # Node::Extracted accessors. Consider if your code is reading
    # doc.address.phone_number.area_code - this will raise an error if any one of
    # these were not extracted. (doc/'address/phone_number/area_code') is
    # preferred. Numbered list_items can be queried e.g. (doc/'comment_list/2'),
    # and basic globbing is supported: (doc/'*/*/title').
    def search(search_string)
      queue=search_string.split '/'
      current_term=queue.shift
      return [self] if current_term.nil? #If for some reason nothing is given in the search string
      matches=[]
      if current_term=='*'
				new_matches=self.children.values
				new_matches.sort! {|a, b| a.node_name <=> b.node_name} rescue nil #is this evil?
        matches.concat new_matches
      elsif current_term[/\d+/]==current_term
        matches << @children[current_term.to_i]
      else
        matches << @children[current_term.to_sym]
      end
      if queue.empty?
        return matches.flatten.compact
      else
        return matches.collect {|match| match.search(queue.join('/'))}.flatten.compact
      end
    end
    alias :/ :search

    # Acts exactly like #search, but returns only the first match or nil if
    # there are no matches.
    def at(search_string)
      self.search(search_string).first
    end

		def inspect
			[super,
			"structure_node=#{self.structure_node.node_name.inspect};",
			"extracted_text=\"#{text=self.extracted_text; text.size > 100 ? text[0..100]+'...' : text}\";"
			].join ' '
		end
  end
end
