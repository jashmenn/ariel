require 'ariel'
require 'fixtures'

include Fixtures

context "Refining non exhaustive rule candidates" do
  setup do
    @candidates=[]
    @candidates << Ariel::Rule.new([[:anything]], :forward)
    @candidates << Ariel::Rule.new([[:numeric], [:numeric], [:numeric]], :forward) #late
    @candidates << Ariel::Rule.new([["("]], :forward)
    @candidates << Ariel::Rule.new([[:numeric, :alpha_numeric]], :forward)
    @refiner=Ariel::CandidateRefiner.new(@candidates, @@labeled_addresses)
  end

  specify "refine_by_match_type should not change the list of candidates if all rules match one of the given types" do
    @refiner.refine_by_match_type :fail, :early, :late, :perfect
    @refiner.candidates.should_equal @candidates
  end

  specify "refine_by_match_type should remove all candidates that don't match the given type from the candidates list" do
    @refiner.refine_by_match_type :late
    @refiner.candidates.size.should_equal 1
    @candidates[1].should_equal @refiner.candidates[0]
  end

  specify "refine_by_fewer wildcards should leave only those rules with the lowest number of wildcards" do
    @refiner.refine_by_fewer_wildcards
    @refiner.candidates.size.should_equal 1
    @refiner.candidates[0].should_equal @candidates[2]
  end

  specify "refine_by_label_proximity should leave only those candidates that match closest to the label" do
    @refiner.refine_by_label_proximity
    @refiner.candidates.size.should_equal 1
    @refiner.candidates[0].should_equal @candidates[2]
  end

  specify "refine_by_longer_end_landmarks should leave only those candidates with the longest end landmark" do
    @refiner.refine_by_longer_end_landmarks
    @refiner.candidates.size.should_equal 1
    @refiner.candidates[0].should_equal @candidates[3]
  end

  specify "random_from_remaining should return a random candidate from those remaining in the candidate list" do
    @candidates.should_include(@refiner.random_from_remaining)
  end
end
