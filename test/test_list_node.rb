require 'test/unit'
require 'ariel'

class TestListNode < Test::Unit::TestCase
  def test_unnested_lists
    assert (Ariel::Node.new {picture_list; title_list; description_list; url_list})
  end

  def test_nested_with_list
    doc_tree=Ariel::Node.new do
      restaurant_list do
        name
        address
        phone
        review
        credit_card_list do
          credit_card
        end
      end
    end
    assert doc_tree
    assert_equal Ariel::ListNode, doc_tree.restaurant_list.class
  end
end
