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
    alias :to_s :extracted_text
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

    def original_text
      self.tokenstream.original_text
    end

    # Converts the tree below and including the current node to a REXML::Document instance.
    def to_rexml
      require 'rexml/document'
      doc = REXML::Document.new
      doc << REXML::XMLDecl.default
      root_el=REXML::Element.new self.structure_node.node_name.to_s
      doc.add_element root_el
      mapping_hash={self => root_el}
      self.each_level do |level|
        level.sort! {|a, b| a.tokenstream <=> b.tokenstream}
        node_parent=level.first.parent  # Parent will be the same for all on this level
        xml_parent = mapping_hash[node_parent]
        last_text_pos = node_parent.tokenstream.tokens.first.start_loc
        level.each do |node|
          xml_parent.add_text(node.parent.original_text[last_text_pos...node.tokenstream.tokens.first.start_loc])
          el = REXML::Element.new node.structure_node.node_name.to_s
          if node.children.empty?
            el.add_text node.to_s
          end
          mapping_hash[node.parent].add_element el
          mapping_hash[node]=el
          last_text_pos = node.tokenstream.tokens.last.end_loc
        end
        # Add any text at the end of the section of the document covered by this tree level
        pos_of_last_string=level.last.tokenstream.tokens.last.end_loc 
        end_of_cur_level=node_parent.tokenstream.tokens.last.end_loc
        xml_parent.add_text(node_parent.original_text[pos_of_last_string..end_of_cur_level])
      end
      return doc
    end

    # Converts the tree to a string of valid XML. See also #to_rexml.
    def to_xml
      output=""
      self.to_rexml.write output
    end

  end
end
