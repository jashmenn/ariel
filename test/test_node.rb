require 'test/unit'
require 'ariel'

class TestNode < Test::Unit::TestCase
  def setup
    @tree=Ariel::Node.new do
      item_info do
        title
        price
        stock_level
      end
    end
  end
  def test_unnested
    assert (Ariel::Node.new {picture; title; description; url})
  end

  def test_nested
    assert @tree.item_info.methods.include?('title')
  end

  def test_add_children
    assert (@tree.add_children {site_copyright; logo;})
    assert @tree.methods.include?('site_copyright')
    assert @tree.methods.include?('logo')
    assert (@tree.item_info.add_children {picture})
    assert @tree.item_info.methods.include?('picture')
  end


end
