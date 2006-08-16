require 'ariel'
require 'fixtures'

include Fixtures
context "A RuleSet of non-exhaustive rules" do
  setup do
    @frule1=Ariel::Rule.new [["1"]], :forward
    @frule2=Ariel::Rule.new [["2"]], :forward
    @brule1=Ariel::Rule.new [["a"]], :back
    @brule2=Ariel::Rule.new [["b"]], :back
    @ruleset=Ariel::RuleSet.new [@frule1, @frule2], [@brule1, @brule2]
    @tokenstream=Ariel::TokenStream.new
    @tokenstream.tokenize "This is a test. 1 Let's see 2. You know a? what about b"
  end

  specify "Should return a tokenstream in an array split at the position where the first forward and back rules match" do
    result=@ruleset.apply_to @tokenstream
    result.should_be_a_kind_of Array
    result.size.should_equal 1
    result[0].should_be_a_kind_of Ariel::TokenStream
    result[0].tokens.first.text.should_equal "Let"
    result[0].tokens.last.text.should_equal "know"
  end

  specify "Should use the next forward or back rule if the first doesn't match" do
    @tokenstream2=Ariel::TokenStream.new
    @tokenstream2.tokenize "Only 2 and b in here"
    result=@ruleset.apply_to @tokenstream2
    result.size.should_equal 1
    result[0].tokens.first.text.should_equal "and"
    result[0].tokens.last.text.should_equal "and"
  end
end

context "A RuleSet of exhaustive rules" do
  setup do
    @tokenstream=Ariel::TokenStream.new
    @tokenstream.tokenize <<EOS
<li>Item number one</li>
<li>Item number two</li>
<li>Item number three</li>
EOS
    @frule=Ariel::Rule.new [["<li>"]], :forward, true
    @brule = Ariel::Rule.new [["</li>"]], :back, true
    @ruleset=Ariel::RuleSet.new [@frule], [@brule]
  end

  specify "Should return an array of all matches found by applying the rules exhaustively" do
    result=@ruleset.apply_to @tokenstream
    result.size.should_equal 3
    result.each {|tokenstream| tokenstream.tokens.first.text.should_equal "Item"}
  end
end

context "Applying exhaustive rules to a document where the location of the first end_match is before the first start match" do
  setup do
    @tokenstream=Ariel::TokenStream.new
    @tokenstream.tokenize @@unlabeled_restaurant_example
    @tokenstream=@tokenstream.slice_by_token_index(12, (@tokenstream.tokens.size - 2))
    @frule=Ariel::Rule.new [["<i>"]], :forward, true
    @brule=Ariel::Rule.new [["</i>"]], :back, true
    @ruleset=Ariel::RuleSet.new [@frule], [@brule]
  end

  specify "Should return correct matches" do
    result=@ruleset.apply_to @tokenstream
    result.size.should_equal 3
    result[0].tokens.first.text.should_equal "4000"
    result[1].tokens.first.text.should_equal "523"
    result[2].tokens.first.text.should_equal "403"
  end
end

