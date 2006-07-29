require 'ariel'
require 'ariel_test_case'

class TestRule < Ariel::TestCase
  def setup
    @labeled=Ariel::TokenStream.new
    @labeled.tokenize("90 Colfax, <b> Palms </b>, Phone: (818) 508-1570")
    @labeled.set_label_at 35
    @perfect_rule=Ariel::Rule.new(["Phone"], ["("])
    @early_rule=Ariel::Rule.new([:anything])
    @late_rule=Ariel::Rule.new(["508"])
    @unlabeled=Ariel::TokenStream.new
    @unlabeled.tokenize("Robot 9753 reporting for duty. BEEP BEEP")
  end

  def test_apply_to
    assert_equal :perfect, @perfect_rule.apply_to(@labeled).type
    assert_equal :early, @early_rule.apply_to(@labeled).type
    assert_equal :late, @late_rule.apply_to(@labeled).type
    assert_nil @perfect_rule.apply_to(@unlabeled)
    assert_nil @early_rule.apply_to(@unlabeled).type
    assert_equal 1, @early_rule.apply_to(@unlabeled).token_loc
  end

  def test_matches
    assert(@early_rule.matches(@labeled, :early))
    assert(@late_rule.matches(@labeled, :early, :late))
    assert(@perfect_rule.matches(@labeled))
    assert_equal(false, @perfect_rule.matches(@unlabeled))
    assert_equal(false, @early_rule.matches(@unlabeled, :early)) #Passing a match type on an unlabeled example
    assert(@perfect_rule.matches(@unlabeled, :fail))
  end

  def test_wildcard_count
    assert_equal 0, @perfect_rule.wildcard_count
    assert_equal 1, @early_rule.wildcard_count
  end
end
