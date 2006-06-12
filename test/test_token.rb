require 'test/unit'
require 'ariel'

class TestToken < Test::Unit::TestCase
  def setup
    @t=Ariel::Token.new('Test', 0, 4)
  end
  
  def test_validation
    assert_raise(ArgumentError) {Ariel::Token.new('Test', 1, 3)}
  end

  def test_matches?
    assert @t.matches?('Test')
    assert_equal false, @t.matches?('test')
    assert_equal false, @t.matches?('te')
    assert @t.matches?(:alpha)
    assert_equal false, @t.matches?(:html_tag)
  end
end
