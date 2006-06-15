require 'test/unit'
require 'ariel'

class TestLearner < Test::Unit::TestCase
  def setup
    #Examples stolen from the STALKER paper. Target to extract is the area
    #codes.
    @e=Array.new(4) {Ariel::LabeledStream.new}
    @e[0].tokenize("513 Pico <b>Venice</b>, Phone: 1-<b>800</b>-555-1515", 36)
    @e[1].tokenize("90 Colfax, <b> Palms </b>, Phone: (818) 508-1570", 35)
    @e[2].tokenize("523 1st St., <b> LA </b>, Phone: 1-<b>888</b>-578-2293", 38)
    @e[3].tokenize("403 La Tijera, <b> Watts </b>, Phone: (310) 798-0008", 39)
    @learner=Ariel::Learner.new(*@e)
  end

  def test_set_seed
    assert_equal @e[1], @learner.current_seed # LabeledStream with smallest label_index
  end

  def test_generate_initial_candidates
    t = @learner.generate_initial_candidates
    assert (t.include? [["("]])
    assert (t.include? [[:anything]])
    assert (t.include? [[:punctuation]])
  end

  def test_test_rule
    assert_equal :perfect_match, @learner.test_rule(@e[1], [["Phone"], ["("]])
    assert_equal :early_match, @learner.test_rule(@e[1], [[:anything]])
    assert_equal :late_match, @learner.test_rule(@e[1], [["508"]])
    assert_nil @learner.test_rule(@e[1], [["Hawaii"]])
  end

  def test_rule_covers?
    assert_equal false, @learner.rule_covers?(@e[1], [["Hawaii"]])
    assert @learner.rule_covers?(@e[1], [["Phone"], ["("]])
  end

  def test_refine
    @learner.current_rule=[["<b>"]]
    assert @learner.refine
  end
end
