require 'ariel'
require 'ariel_test_case'

class TestWildcards < Ariel::TestCase
  
  def test_list
    assert (wildcards=Ariel::Wildcards.list)
    assert (wildcards.kind_of? Hash)
  end

  def test_matching
    assert matches=Ariel::Wildcards.matching("123")
    assert (matches.include? :alpha_numeric)
    assert (matches.include? :numeric)
    assert (matches.include? :anything)
    assert_equal 3, matches.size
  end
end
