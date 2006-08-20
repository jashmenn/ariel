require 'ariel'
require 'fixtures'

include Fixtures

context "Creating a new Node::Structure tree" do
  setup do
    @node=Ariel::Node::Structure.new
  end

  specify "Should default to :root as the node_name" do
    @node.node_name=:root
  end

  specify "Should be possible to create a node with node_type :list_item" do
    list_node=Ariel::Node::Structure.new :comments, :list_item
    list_node.node_type.should_equal :list_item
  end

  specify "Node::Structure#new should yield itself is a block is given" do
    result=[]
    new_node=Ariel::Node::Structure.new {|r| result << r}
    result.should_equal [new_node]
  end

  specify "Node::Structure#item should create a new child with the given name and of a non-list node_type" do
    @node.item :test
    @node.children.keys.should_include :test
    @node.test.should_be_an_instance_of Ariel::Node::Structure
    @node.test.node_type.should_not_equal :list_item
  end

  specify "Node::Structure#list_item should create a new child with the given name and node_type :list_item" do
    @node.list_item :list
    @node.children.keys.should_include :list
    @node.list.should_be_an_instance_of Ariel::Node::Structure
    @node.list.node_type.should_equal :list_item
  end

  specify "Should be possible to define a tree by passing blocks to item and list_item" do
    root=@@labeled_document_with_list_structure
    root.title.parent.should_equal root
    root.comment_list.comment.should_respond_to :author
  end

  specify "#extend_structure should allow new children to be added to an existing Node::Structure" do
    @node.extend_structure {|r| r.item :test1}
    @node.extend_structure {|r| r.list_item :test2}
    @node.children.keys.should_include :test1
    @node.children.keys.should_include :test2
  end
end

context "Applying a tree of Node::Structure objects to extract a tree of Node::Extracted objects, some children don't have rulesets defined" do
  setup do
    @structure_root=@@labeled_document_with_list_structure
    @tokenstream=Ariel::TokenStream.new
    @tokenstream.tokenize Ariel::LabelUtils.clean_string(@@labeled_document_with_list)
    @extracted_root=Ariel::Node::Extracted.new :root, @tokenstream, @structure_root
  end

  specify "#extract_from should apply the ruleset in the given Node::Structure to extract and return an array new Node::Extracted" do
    extractions=@structure_root.title.extract_from @extracted_root
    extractions.size.should_equal 1
    extractions[0].extracted_text.should_equal "Another example"
  end

  specify "#apply_extraction_tree_on should apply the RuleSet in every Node::Structure child and add all extracted children to the given Node::Extracted" do
    @structure_root.apply_extraction_tree_on @extracted_root
    [:title, :body, :comment_list].each {|node| @extracted_root.children.keys.should_include node}
    @extracted_root.comment_list.children.size.should_equal 2
    @extracted_root.comment_list.children[0].children.should_equal({})
  end
end
