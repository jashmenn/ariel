require 'ariel'
require 'ariel_test_case'

class TestRule < Ariel::TestCase
  def setup
    @labeled=Ariel::TokenStream.new
    @labeled.tokenize("90 Colfax, <b> Palms </b>, Phone: (818) 508-1570")
    @labeled.set_label_at 35
    @perfect_rule=Ariel::Rule.new(:forward, [["Phone"], ["("]])
    @early_rule=Ariel::Rule.new(:forward, [[:anything]])
    @late_rule=Ariel::Rule.new(:forward, [["508"]])
    @unlabeled=Ariel::TokenStream.new
    @unlabeled.tokenize("Robot 9753 reporting for duty. BEEP BEEP")
  end

  def test_apply_to
    md=nil
    @perfect_rule.apply_to(@labeled) {|md|}
    assert_equal :perfect, md.type
    @early_rule.apply_to(@labeled) {|md|}
    assert_equal :early, md.type
    assert_equal 1, md.token_loc
    @late_rule.apply_to(@labeled) {|md|}
    assert_equal :late, md.type
    assert_equal [], (@perfect_rule.apply_to(@unlabeled))
  end

  def test_matches
    assert(@early_rule.matches(@labeled, :early))
    assert(@late_rule.matches(@labeled, :early, :late))
  end

  def test_wildcard_count
    assert_equal 0, @perfect_rule.wildcard_count
    assert_equal 1, @early_rule.wildcard_count
  end
end
