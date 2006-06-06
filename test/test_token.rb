require 'test/unit'
require 'ariel'

class TestToken < Test::Unit::TestCase
  def setup
    @t=Ariel::Token.new('Test', 0, 4)
  end
  
  def test_text  #These tests are stupid, however start_loc and end_loc should maybe have some validation?
    assert_equal 'Test', @t.text
  end
  
  def test_start_loc
    assert_equal 0, @t.start_loc
  end
  
  def test_end_loc
    assert_equal 4, @t.end_loc
  end

  def test_matches?
    assert @t.matches?('Test')
    assert_equal false, @t.matches?('test')
    assert_equal false, @t.matches?('te')
    assert @t.matches?(:alpha)
    assert_equal false, @t.matches?(:html_tag)
  end
end
