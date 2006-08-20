require 'ariel'
require 'fixtures'
include Fixtures

context "Querying LabelUtils for label tag locating Regular Expressions" do
  specify "label_regex should return an array of two Regexp to locate a start tag or an end tag with the given tag contents" do
    s_regex, e_regex = Ariel::LabelUtils.label_regex('example')
    s_tag="<l:example>"
    e_tag="</l:example>"
    s_tag.should_match s_regex
    e_tag.should_not_match s_regex
    s_tag.should_not_match e_regex
    e_tag.should_match e_regex
    "<l:fail>".should_not_match s_regex
  end

  specify "label_regex should by default return a pair of labels that will match any valid label tags" do
    s_regex, e_regex = Ariel::LabelUtils.label_regex
    "<l:randomexample>".should_match s_regex
    "</l:unrandomexample>".should_match e_regex
    "<l:foo>".should_not_match e_regex
  end

  specify "any_label_regex should return a regex that will match any valid open or closing label tags" do
    regex=Ariel::LabelUtils.any_label_regex
    regex.should_be_a_kind_of Regexp
    %w[<l:foo> <l:bar> </l:foo> </l:bar>].each {|tag| tag.should_match regex}
    %w[<l:foo <l/trunk> </l:** <a> </b>].each {|tag| tag.should_not_match regex}
  end
end

context "Extracting a labeled region from a node" do
  setup do
    @tokenstream_with_label_tags = Ariel::TokenStream.new
    @tokenstream_with_label_tags.tokenize @@labeled_document, true
    @parent_extracted_node=Ariel::Node::Extracted.new(:root, @tokenstream_with_label_tags, @@labeled_document_structure)
    @title_result=Ariel::LabelUtils.extract_labeled_region(@@labeled_document_structure.title, @parent_extracted_node)
  end
  
  specify "extract_labeled_region should return an array containing the region corresponding to the given structure node as a Node::Extracted" do
    @title_result.should_be_a_kind_of Array
    @title_result[0].should_be_an_instance_of Ariel::Node::Extracted
    @title_result.size.should_equal 1
    @title_result[0].tokenstream.tokens.should_equal @tokenstream_with_label_tags.tokens[3..7]
  end

  specify "Should return an empty array if the match fails" do
    Ariel::LabelUtils.extract_labeled_region(Ariel::Node::Structure.new(:non_existent), @parent_extracted_node).should_equal []
  end

  specify "Extracted node should have the correct node_name" do
    @title_result[0].node_name.should_equal :title
  end

  specify "Extracted node should be added as a child to the parent extracted node" do
    @title_result.should_equal @parent_extracted_node.children.values
  end
end

context "Extracting labeled list items from a node" do
  setup do
    @structure=@@labeled_document_with_list_structure
    @tokenstream=Ariel::TokenStream.new
    @tokenstream.tokenize @@labeled_document_with_list, true
    @tokenstream = @tokenstream.slice_by_token_index 39, 95
    @parent_extracted_node=Ariel::Node::Extracted.new(:comment_list, @tokenstream, @@labeled_document_with_list_structure.comment_list)
    @result = Ariel::LabelUtils.extract_labeled_region(@structure.comment_list.comment, @parent_extracted_node) 
  end

  specify "Should return an array containing each list_item" do
    @result.size.should_equal 2
    @result.each {|extracted_node| extracted_node.should_be_an_instance_of Ariel::Node::Extracted}
    @tokenstream.tokens[5..28].should_equal @result[0].tokenstream.tokens
    @tokenstream.tokens[33..54].should_equal @result[1].tokenstream.tokens

  end

  specify "Should name each list item itemname_num" do
    @result[0].node_name.should_equal :comment_0
    @result[1].node_name.should_equal :comment_1
  end

  specify "Should add each list_item as as a child of the parent extracted node" do
    children=@parent_extracted_node.children.values
    children.size.should_equal 2
    children.each {|child| @result.should_include child}
  end

  specify "Should return an empty array if no list items are extracted" do
    stream=Ariel::TokenStream.new
    stream.tokenize "No labels here", true
    @parent_extracted_node.tokenstream=stream
    result = Ariel::LabelUtils.extract_labeled_region(@structure.comment_list.comment, @parent_extracted_node)
    result.should_equal []
  end

end
