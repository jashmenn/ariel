require 'ariel'
require 'breakpoint'

context "A new Node::Extracted" do
  setup do
    @tokenstream=Ariel::TokenStream.new
    @tokenstream.tokenize "This is a test"
    @structure=Ariel::Node::Structure.new :test
    @node=Ariel::Node::Extracted.new :test, @tokenstream, @structure
  end

  specify "Should provide an accessor for its tokenstream" do
    @node.tokenstream.should_equal @tokenstream
  end

  specify "Should provide an accessor, structure_node for its structure node" do
    @node.structure_node.should_equal @structure
  end

  specify "Should provide a method extracted_text to show the content of the tokenstream" do
    @node.extracted_text.should_equal @tokenstream.text
  end
end

context "A Node::Extracted with children" do
	setup do
		@tokenstream=Ariel::TokenStream.new
    @tokenstream.tokenize "This is a dummy"
		@structure=@@labeled_document_with_list_structure
		@root=Ariel::Node::Extracted.new :root, @tokenstream, @structure
		[:title, :comment_list].each do |name|
			@root.add_child(Ariel::Node::Extracted.new(name, @tokenstream, @structure.children[name]))
		end
		0.upto 10 do |i|
			@root.comment_list.add_child Ariel::Node::Extracted.new(i, @tokenstream, @structure.comment_list.comment)
		end
	end

	specify "should provide access to the node's children through" do #[] can't be used in a spec name due to a bug
		@root[:comment_list].node_name.should_equal :comment_list
		@root.comment_list[2].node_name.should_equal 2
	end

  specify "square bracket method should return an array when a Range with one member is given" do
    @root.comment_list[0..0].should_be_a_kind_of Array
  end

  specify "square bracket should return nil if no matches exist" do
    @root[:monkey].should_be_nil
    @root[:monkey, :heaven].should_be_nil
  end

  specify "square bracket should return those matches that do exist in an array even if some don't" do
    result=@root[:monkey, :title]
    result.size.should_equal 1
    result[0].node_name.should_equal :title
  end

  specify "#search should return an array of any and all matches to the given query" do
    result=(@root/'comment_list')
    result.should_be_a_kind_of Array
    result.size.should_equal 1
    result[0].node_name.should_equal :comment_list
  end

  specify "#search should return an empty array on match failure" do
    (@root/'monkey').should_equal []
  end

  specify "#search should accept * as a wildcard" do
    @root.title.add_child Ariel::Node::Extracted.new(:test, @tokenstream, @structure)
    result=(@root/'*/*').collect {|r| r.node_name}
    (((0..10).to_a << :test) - result).should_equal []
  end

  specify "#search should return numbered children" do
    result=(@root.comment_list/'0')
    result.size.should_equal 1
    result[0].node_name.should_equal 0
  end

	specify "#search should return sorted results when a wildcard is used" do
		result=(@root/'comment_list/*').collect {|node| node.node_name}
		result.should_equal ((0..10).to_a)
	end

	specify "#at should act like #search, but return only the first result" do
		@root.at('comment_list/*').node_name.should_equal 0
	end

end	
