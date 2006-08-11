require 'ariel'
require 'ariel_test_case'


class TestCandidateSelector < Ariel::TestCase
  include Fixtures
  def setup
    # Must get rid of this repetition, should be available to all tests
    @e=@@labeled_addresses
    @candidates=[]
    @candidates << Ariel::Rule.new(:forward, [[:anything]])
    @candidates << Ariel::Rule.new(:forward, [[:numeric], [:numeric], [:numeric]])
    @candidates << Ariel::Rule.new(:forward, [["("]])
    @candidates << Ariel::Rule.new(:forward, [[:numeric, :alpha_numeric]])
    @refiner=Ariel::CandidateRefiner.new(@candidates, @e)
  end

  def test_refine_by_match_type
    @refiner.refine_by_match_type :fail, :early, :late, :perfect
    assert_equal @candidates, @refiner.candidates
    @refiner.refine_by_match_type :late
    assert_equal 1, @refiner.candidates.size
    assert_equal @candidates[1], @refiner.candidates[0]
  end

  def test_refine_by_fewer_wildcards
    assert_equal @refiner.refine_by_fewer_wildcards[0], @candidates[2]
    assert_equal 1, @refiner.candidates.size
  end

  def test_refine_by_label_proximity
    assert_equal @candidates[2], @refiner.refine_by_label_proximity[0]
    assert_equal 1, @refiner.candidates.size
  end

  def test_refine_by_longer_end_landmarks
    assert_equal @candidates[3], @refiner.refine_by_longer_end_landmarks[0]
    assert_equal 1, @refiner.candidates.size
  end

  def test_random_from_remaining
    assert(@candidates.include?(@refiner.random_from_remaining))
  end
end
