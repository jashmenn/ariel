require 'ariel'
require 'ariel_test_case'

class TestStructureNode < Ariel::TestCase
  def setup
    @tree=Ariel::StructureNode.new do |r|
      r.item_info do |i|
        i.title
        i.price
        i.stock_level
      end
    end
  end
  def test_unnested
    t=Ariel::StructureNode.new {|r| r.picture; r.title; r.description; r.url}
    assert t
    assert_equal Ariel::StructureNode, t.picture.class
    p t.meta.name
    p t.picture.meta.name
  end

  def test_nested
    assert @tree.item_info.methods.include?('title')
  end

  def test_unnested_lists
    assert (Ariel::StructureNode.new {|r| r.picture_list; r.title_list; r.description_list; r.url_list})
  end

  def test_nested_with_list
    doc_tree=Ariel::StructureNode.new do |r|
      r.restaurant_list do |r|
        r.name
        r.address
        r.phone
        r.review
        r.credit_card_list do |c|
          c.credit_card
        end
      end
    end
    assert doc_tree
    assert_equal :list, doc_tree.restaurant_list.meta.node_type
  end

  def test_extend
    assert (@tree.extend {|r| r.site_copyright; r.logo;})
    assert @tree.methods.include?('site_copyright')
    assert @tree.methods.include?('logo')
    assert (@tree.item_info.extend {|i| i.picture})
    assert @tree.item_info.methods.include?('picture')
  end

  def test_apply_extraction_tree_on
    t = Ariel::StructureNode.new do |r|
      r.title
      r.content do |c|
        c.excerpt
        c.body
      end
    end
    str = %q{Title: The test of the Century
<b>Excerpt</b>: <i>A look back at what could be considered the greatest ever test.</i>
There was once a test designed to assess whether apply_extraction_tree_on worked.}
    tokenstream = Ariel::TokenStream.new
    tokenstream.tokenize(str)
    root = Ariel::ExtractedNode.new(tokenstream, :structure=>t, :name=>:root)
    t.title.meta.start_rule = Ariel::Rule.new(["Title", ":"])
    t.title.meta.end_rule = Ariel::Rule.new(["<b>"])
    t.title.meta.end_rule.direction = :back
    t.content.meta.start_rule = Ariel::Rule.new(["Century"]) #later implementation might use skip_until("<b>")
    t.content.meta.end_rule = Ariel::Rule.new()
    t.content.meta.end_rule.direction = :back
    t.content.excerpt.meta.start_rule = Ariel::Rule.new(["<i>"])
    t.content.excerpt.meta.end_rule = Ariel::Rule.new([".</"])
    t.content.excerpt.meta.end_rule.direction = :back
    t.content.body.meta.start_rule = Ariel::Rule.new(["i", ">"])
    t.content.body.meta.end_rule = Ariel::Rule.new()
    t.content.body.meta.end_rule.direction = :back
    t.apply_extraction_tree_on root
  end


end
