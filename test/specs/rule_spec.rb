require 'ariel'
require 'fixtures'
include Fixtures

tokenstream=Ariel::TokenStream.new
tokenstream.tokenize @@unlabeled_document

labeled_tokenstream=Ariel::TokenStream.new
labeled_tokenstream.tokenize @@unlabeled_document
labeled_tokenstream.label_index=4

context "A forward rule with no landmarks" do
  setup do
    @rule=Ariel::Rule.new([], :forward)
  end

  specify "Should return its direction correctly" do
    @rule.direction.should_equal :forward
  end

  specify "Should contain no wildcards" do
    @rule.wildcard_count.should_equal 0
  end

  specify "Should match any tokenstream at index 0" do
    @rule.apply_to(tokenstream).should_equal [0]
  end

  specify "Should not be exhaustive" do
    @rule.should_not_be_exhaustive
  end
end

context "A back rule with no landmarks" do
  setup do
    @rule=Ariel::Rule.new([], :back)
  end

  specify "Should match any tokenstream at its last token" do
    match_loc=@rule.apply_to(tokenstream)
    p match_loc
    tokenstream.tokens[*@rule.apply_to(tokenstream)].should_equal tokenstream.tokens.last
  end
end

context "Creating a new rule" do
  specify "Should not be possible to create a rule with an invalid direction" do
    lambda {Ariel::Rule.new([[:anything]], :upward)}.should_raise
  end
end

context "Applying a non-exhaustive forward rule" do
  setup do
    @rule=Ariel::Rule.new [[:anything]], :forward
  end
  specify "apply_to should return an array of match locations" do
    locs=@rule.apply_to(tokenstream)
    locs.should_equal [1]
  end

  specify "apply_to should yield matchdata with type nil for tokenstreams with no label_index" do
    @rule.apply_to(tokenstream) do |md|
      md.type.should_be_nil
      md.token_loc.should_equal 1
    end
  end

  specify "apply_to should yield match data with type :early, :late, or :perfect for a labeled tokenstream" do
    @rule.apply_to(labeled_tokenstream) do |md|
      md.type.should_equal :early
    end
    late_rule=Ariel::Rule.new [["assess"]], :forward
    late_rule.apply_to(labeled_tokenstream) do |md|
      md.type.should_equal :late
    end
    perfect_rule = Ariel::Rule.new [["test"]], :forward
    perfect_rule.apply_to(labeled_tokenstream) do |md|
      md.type.should_equal :perfect
      md.token_loc.should_equal 4
    end
  end

  specify "matches should return true or false if applying the rule to a labeled tokenstream results in a match of one of the given types" do
    @rule.matches(labeled_tokenstream, :late, :perfect, :fail).should_equal false
    @rule.matches(labeled_tokenstream, :early, :late, :perfect, :fail).should_equal true
    failed_rule=Ariel::Rule.new([["bacon"]], :forward)
    failed_rule.matches(labeled_tokenstream, :fail).should_equal true
  end

  specify "apply_to should apply the rule in the right direction whether the tokenstream is reversed or not. The returned match should be from the left" do
    @rule.apply_to(labeled_tokenstream).should_equal [1]
    @rule.apply_to(labeled_tokenstream.reverse).should_equal [labeled_tokenstream.tokens.size-2]
    
  end

end

context "Applying a non-exhaustive back rule" do

end

context "Applying an exhaustive rule" do
  setup do
    @rule = Ariel::Rule.new [[:html_tag]], :forward, true
  end

  specify "apply_to should return an array of multiple matches" do
    @rule.apply_to(tokenstream).size.should_equal 4
  end
end
