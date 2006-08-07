require 'ariel'
require 'ariel_test_case'

class TestStructureNode < Ariel::TestCase
  def setup
    @tree=Ariel::StructureNode.new do |r|
      r.item :item_info do |i|
        i.item :title
        i.item :price
        i.item :stock_level
      end
    end
  end
  def test_unnested
    t=Ariel::StructureNode.new {|r| r.item :picture; r.item :title; r.item :description; r.item :url}
    assert t
    assert_equal Ariel::StructureNode, t.picture.class
    assert_equal :root, t.meta.name
  end

  def test_nested
    assert @tree.item_info.children.has_key?(:title)
  end

  def test_nested_with_list
    doc_tree=Ariel::StructureNode.new do |r|
      r.item :restaurant_list do |r|
        r.list_item :restaurant do |r|
          r.item :name
          r.item :address
          r.item :phone
          r.item :review
          r.item :credit_card_list do |c|
            c.item :credit_card
          end
        end
      end
    end
    assert doc_tree
    assert_equal :list, doc_tree.restaurant_list.restaurant.meta.node_type
  end

  def test_extend_structure
    assert (@tree.extend_structure {|r| r.item :site_copyright; r.item :logo;})
    assert @tree.children.has_key?(:site_copyright)
    assert @tree.children.has_key?(:logo)
    assert (@tree.item_info.extend_structure {|i| i.item :picture})
    assert @tree.item_info.children.has_key?(:picture)
  end

#   def test_apply_extraction_tree_on
# #     t = Ariel::StructureNode.new do |r|
# # #       r.title
# # # #       r.content do |c|
# # # # #         c.excerpt
# # # # # #         c.body
# # # # # # #       end
# # # # # # # #     end
# # # # # # # # #     str = %q{Title: The test of the Century
# # # # # # # # # # <b>Excerpt</b>: <i>A look back at what could be considered the greatest ever test.</i>
# # # # # # # # # # # There was once a test designed to assess whether apply_extraction_tree_on worked.}
# # # # # # # # # # # #     tokenstream = Ariel::TokenStream.new
# # # # # # # # # # # # #     tokenstream.tokenize(str)
# # # # # # # # # # # # # #     root = Ariel::ExtractedNode.new(tokenstream, :structure=>t, :name=>:root)
# # # # # # # # # # # # # # #     t.title.meta.start_rule = Ariel::Rule.new(["Title", ":"])
# # # # # # # # # # # # # # # #     t.title.meta.end_rule = Ariel::Rule.new(["<b>"])
# # # # # # # # # # # # # # # # #     t.title.meta.end_rule.direction = :back
# # # # # # # # # # # # # # # # # #     t.content.meta.start_rule = Ariel::Rule.new(["Century"]) #later implementation might use skip_until("<b>")
# # # # # # # # # # # # # # # # # # #     t.content.meta.end_rule = Ariel::Rule.new()
# # # # # # # # # # # # # # # # # # # #     t.content.meta.end_rule.direction = :back
# # # # # # # # # # # # # # # # # # # # #     t.content.excerpt.meta.start_rule = Ariel::Rule.new(["<i>"])
# # # # # # # # # # # # # # # # # # # # # #     t.content.excerpt.meta.end_rule = Ariel::Rule.new([".</"])
# # # # # # # # # # # # # # # # # # # # # # #     t.content.excerpt.meta.end_rule.direction = :back
# # # # # # # # # # # # # # # # # # # # # # # #     t.content.body.meta.start_rule = Ariel::Rule.new(["i", ">"])
# # # # # # # # # # # # # # # # # # # # # # # # #     t.content.body.meta.end_rule = Ariel::Rule.new()
# # # # # # # # # # # # # # # # # # # # # # # # # #     t.content.body.meta.end_rule.direction = :back
# # # # # # # # # # # # # # # # # # # # # # # # # # #     t.apply_extraction_tree_on root
#  end


end
