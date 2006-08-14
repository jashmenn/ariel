require 'ariel'

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

