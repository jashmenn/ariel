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

  specify "Should be possible to create a node with node_type :list" do
    list_node=Ariel::Node::Structure.new :comments, :list
    list_node.node_type.should_equal :list
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
    @node.test.node_type.should_not_equal :list
  end

  specify "Node::Structure#list_item should create a new child with the given name and node_type :list" do
    @node.list_item :list
    @node.children.keys.should_include :list
    @node.list.should_be_an_instance_of Ariel::Node::Structure
    @node.list.node_type.should_equal :list
  end

  specify "Should be possible to define a tree by passing blocks to item and list_item" do
    root=@@labeled_document_with_list_structure
    root.title.parent.should_equal root
    root.comment_list.comment.should_respond_to :author
  end
end
