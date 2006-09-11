require 'ariel'

context "A new Node" do
  setup do
    @node=Ariel::Node.new(:root)
  end
  
  specify "Should have an empty hash of children" do
    @node.children.should_equal Hash.new
  end

  specify "Should give its node_name as a symbol" do
    @node.node_name.should_equal :root
  end

  specify "Should not have a parent" do
    @node.parent.should_be_nil
  end

  specify "Should yield nothing if each_descendant is called with no arguments" do
    results=[]
    @node.each_descendant {|child| results << child}
    results.should_equal []
  end

  specify "Should yield only itself if each_descendant is called with true as its argument" do
    results=[]
    @node.each_descendant(true) {|child| results << child}
    results.size.should_equal 1
    results[0].should_equal @node
  end

  specify "Should not respond to :id or :type" do
    @node.should_not_respond_to :id
    @node.should_not_respond_to :type
  end
end

context "Building a tree of Node objects" do
  setup do
    @root_parent=Ariel::Node.new :root
    @child1=Ariel::Node.new :child1
    @child2=Ariel::Node.new :child2
    @child1_1=Ariel::Node.new :child1_1
  end

  specify "Adding a child should add an entry to the parent's children hash with the child's node_name as the key" do
    @root_parent.add_child @child1
    @root_parent.children[:child1].should_equal @child1
  end

  specify "When adding a node as a child, its parent should be set appropriately" do
    @root_parent.add_child @child1
    @child1.parent.should_equal @root_parent
    @child1.add_child @child1_1
    @child1_1.parent.should_equal @child1
  end

  specify "When adding a node as a child, an accessor method should be created in the parent with name corresponding to the child's node_name" do
    @root_parent.add_child @child1
    @root_parent.should_respond_to :child1
    @root_parent.child1.should_equal @child1
  end

  specify "Should yield all children when iterating over each_descendant" do
    @root_parent.add_child @child1
    @root_parent.add_child @child2
    @child1.add_child @child1_1
    results=[]
    @root_parent.each_descendant {|child| results << child}
    results.size.should_equal 3
    results.should_include @child1
    results.should_include @child2
    results.should_include @child1_1
  end

  specify "Should yield the children at each level when using each_level" do
    @root_parent.add_child @child1
    @root_parent.add_child @child2
    @child1.add_child @child1_1
    results=[]
    @root_parent.each_level do |level|
      results << level
    end
    results[0].size.should_equal 2
    results[1].should_equal [@child1_1]
    results.size.should_equal 2
  end

  specify "#each_level should work for many levels and return the current node when include_self=true" do
    r=Ariel::Node.new :r
    c1=Ariel::Node.new :c1
    c1_1=Ariel::Node.new :c1_1
    c2=Ariel::Node.new :c2
    c3=Ariel::Node.new :c3
    c4=Ariel::Node.new :c4
    c5=Ariel::Node.new :c5
    
    r.add_child c1
    c1.add_child c2
    c1.add_child c1_1
    c2.add_child c3
    c3.add_child c4
    c4.add_child c5

    results=[]
    r.each_level(true) do |level|
      results << level
    end
    results[0].should_equal [r]
    results[1].should_equal [c1]
    results[2].should_include c1_1
    results[2].should_include c2
    results[2].size.should_equal 2
    results[3].should_equal [c3]
    results[4].should_equal [c4]
    results[5].should_equal [c5]
  end
end
