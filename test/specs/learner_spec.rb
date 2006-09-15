require 'ariel'
require 'fixtures'
include Fixtures
Ariel::Log.set_level :debug
context "A non-exhaustive forward rule learner" do
  setup do
    @learner=Ariel::Learner.new(*@@labeled_addresses)
  end

  specify "set_seed should choose the example with the smallest number of tokens before the label" do
    @learner.send(:set_seed).should_equal @@labeled_addresses[1]
  end

  specify "generate_initial_candidates should generate rule candidates based on the token before the label in the current_seed" do
    @learner.direction=:forward
    @learner.send(:set_seed)
    c=@learner.generate_initial_rules
    c.should_include Ariel::Rule.new([["("]], :forward)
    c.should_include Ariel::Rule.new([[:anything]], :forward)
    c.should_include Ariel::Rule.new([[:punctuation]], :forward)
  end

  specify "learn_rule should return an array of the Rule's learnt" do
    rules=@learner.learn_rule :forward
    rules.should_be_a_kind_of Array
    rules.should_not_be_empty
  end

  specify "generated rules should be of a :forward type and non-exhaustive" do
    rule=@learner.learn_rule(:forward).first
    rule.direction.should_equal :forward
    rule.should_not_be_exhaustive
  end
end
