require 'ariel'

context "An average token" do
  setup do
    @token = Ariel::Token.new("Test", 0, 4)
  end
  specify "Should return the string it holds when text is called" do
    @token.text.should_equal "Test"
  end

  specify "Should not be a label tag" do
    @token.is_label_tag?.should_be false
  end

  specify "Should return true if if the token string matches a given wildcard or equals a given string" do
    @token.matches?("Test").should_be true
    @token.matches?(:alpha_numeric).should_be true
  end

  specify "Should return false if the token string doesn't match the given wildcard or string" do
    @token.matches?("Tes").should_be false
    @token.matches?(:html_tag).should_be false
  end

  specify "Should raise an error if an invalid wildcard is given" do
    lambda {@token.matches? :not_a_wildcard}.should_raise ArgumentError
  end

  specify "Should be able to list all wildcard symbols that match its text" do
    @token.matching_wildcards.should_be_an_instance_of Array
    @token.matching_wildcards.each {|wildcard| wildcard.should_be_an_instance_of Symbol}
  end
end

context "Comparing two Tokens" do
  setup do
    @token1 = Ariel::Token.new("Alice", 0, 5)
    @token2 = Ariel::Token.new("Bob", 5, 8)
    @token1_clone = Ariel::Token.new("Alice", 0, 5)
    @token1_almost_clone = Ariel::Token.new("Alice", 0, 4)
  end

  specify "Should be equal if and only if text, start location and end location are equal" do
    @token1.should_equal @token1_clone
    @token1.should_not_equal @token2
    @token1.should_not_equal @token1_almost_clone
  end

  specify "Should define a way of comparing itself to other tokens" do
    @token1.should_respond_to :<=>
  end

  specify "Should make comparisons based on the start location of the token" do
    (@token1<=>@token1_almost_clone).should_equal 0
    (@token1<=>@token2).should_equal -1
  end
end

context "Initializing a label tag token" do
  specify "Should be ignored if passed true as the final argument to Token#new" do
    Ariel::Token.new("Test", 0, 4, true).is_label_tag?.should_be true
  end
end


