require 'ariel'
require 'ariel_test_case'


class TestCandidateSelector < Ariel::TestCase
  include Fixtures
  def setup
    # Must get rid of this repetition, should be available to all tests
    @e=@@labeled_addresses
    @candidates=[]
    @candidates << Ariel::Rule.new([:anything])
    @candidates << Ariel::Rule.new([:numeric], [:numeric], [:numeric])
    @candidates << Ariel::Rule.new(["("])
    @candidates << Ariel::Rule.new([:numeric, :alpha_numeric])
    @selector=Ariel::CandidateSelector.new(@candidates, @e)
  end

  def test_score_by
    score_hash = @selector.score_by {|rule| rule.landmarks.size}
    assert_equal @candidates.size, score_hash.size
    assert_equal 1, score_hash.values.sort.first
  end

  def test_highest_scoring_by
    t1 = @selector.highest_scoring_by {|rule| 1}
    assert (t1.all? {|rule| rule.kind_of? Ariel::Rule})
    assert_equal @candidates.size, t1.size
    t2 = @selector.highest_scoring_by {|rule| rule.landmarks.size}
    assert_equal 1, t2.size
  end

  def test_select_best_by_match_type
    @selector.select_best_by_match_type :fail, :early, :late, :perfect
    assert_equal @candidates, @selector.candidates
    @selector.select_best_by_match_type :late
    assert_equal 1, @selector.candidates.size
    assert_equal @candidates[1], @selector.candidates[0]
  end

  def test_select_with_fewer_wildcards
    assert_equal @selector.select_with_fewer_wildcards[0], @candidates[2]
    assert_equal 1, @selector.candidates.size
  end

  def test_select_closest_to_label
    assert_equal @candidates[2], @selector.select_closest_to_label[0]
    assert_equal 1, @selector.candidates.size
  end

  def test_select_with_longer_landmarks
    assert_equal @candidates[3], @selector.select_with_longer_end_landmarks[0]
    assert_equal 1, @selector.candidates.size
  end

  def test_random_from_remaining
    assert(@candidates.include?(@selector.random_from_remaining))
  end
end
