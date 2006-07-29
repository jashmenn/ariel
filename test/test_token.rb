require 'ariel'
require 'ariel_test_case'

class TestToken < Ariel::TestCase
  def setup
    @t=Ariel::Token.new('Test', 0, 4)
  end

  def test_matches?
    assert @t.matches?('Test')
    assert_equal false, @t.matches?('test')
    assert_equal false, @t.matches?('te')
    assert @t.matches?(:alpha)
    assert_equal false, @t.matches?(:html_tag)
  end
end
