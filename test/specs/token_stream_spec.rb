require 'ariel'
require 'fixtures'
include Fixtures

context "A new, unlabeled TokenStream" do
  setup do
    @tokenstream = Ariel::TokenStream.new
  end

  specify "Should return 0 when cur_pos is called" do
    @tokenstream.cur_pos.should_equal 0
  end

  specify "Should not contain any tokens" do
    @tokenstream.tokens.size.should_equal 0
  end

  specify "Should have an empty string as raw_text" do
    @tokenstream.raw_text.should_equal ""
  end

  specify "Should return nil when asked to advance" do
    @tokenstream.advance.should_be_nil
  end

  specify "cur_pos should increase to 1 when asked to advance and no further" do
    @tokenstream.advance
    @tokenstream.cur_pos.should_equal 1
    @tokenstream.advance
    @tokenstream.cur_pos.should_equal 1
  end

  specify "Should not be reversed" do
    @tokenstream.should_not_be_reversed
  end

  specify "Should have a label_index of nil" do
    @tokenstream.label_index.should_be_nil
  end

  specify "Should accept a string to be tokenized" do
    lambda {@tokenstream.tokenize "This is a test"}.should_not_raise
  end

  specify "Should provide a skip_to method" do
    @tokenstream.should_respond_to :skip_to
  end

  specify "Should not contain label tags" do
    @tokenstream.contains_label_tags?.should_equal false
  end
end

context "A TokenStream instance which has tokenized unlabeled text" do
  setup do
    @tokenstream = Ariel::TokenStream.new
    @tokenstream.tokenize "This is a test you know"
  end

  specify "Should not contain label tags" do
    @tokenstream.contains_label_tags?.should_equal false
  end

  specify "Should return its original text" do
    @tokenstream.raw_text.should_equal @tokenstream.original_text
    @tokenstream.original_text.should_equal @tokenstream.text
  end

  specify "Should contain tokens that correctly identify their position in the original text" do
    @tokenstream.each do |token|
      token.text.should_equal @tokenstream.original_text[token.start_loc...token.end_loc]
    end
  end

  specify "Should have its tokens in order" do
    sorted=@tokenstream.tokens.sort_by {|token| token.start_loc}
    sorted.should_equal @tokenstream.tokens
  end

  specify "Should advance its position when Enumerable methods are called" do
    pos=0
    @tokenstream.each do |token|
      pos+=1
      @tokenstream.cur_pos.should_equal pos
    end
  end

  specify "Should make no changes when remove_label_tags is called" do
    token_n = @tokenstream.tokens.size
    @tokenstream.remove_label_tags
    @tokenstream.tokens.size.should_equal token_n
  end

  specify "Should return its current_token" do
    @tokenstream.cur_pos=2
    @tokenstream.current_token.should_equal @tokenstream.tokens[2]
  end

  specify "Should return its current token and increment cur_pos by one when asked to advance" do
    @tokenstream.cur_pos=3
    @tokenstream.advance.should_equal @tokenstream.tokens[3]
    @tokenstream.cur_pos.should_equal 4
  end

  specify "Should make sure cur_pos still points to the same token when asked to reverse" do
    @tokenstream.cur_pos=1
    @tokenstream.tokens.reverse.should_equal @tokenstream.reverse!.tokens
    @tokenstream.current_token.should_equal @tokenstream.tokens.reverse[1]
  end

  specify "reverse should not modify the receiver" do
    @tokenstream.reverse.should_not_equal @tokenstream
    @tokenstream.reverse.tokens.should_not_equal @tokenstream.tokens
  end

  specify "reversed? should reflect whether the tokenstream is in a reversed state or not" do
    @tokenstream.reverse.reversed?.should_equal true
    @tokenstream.reverse!
    @tokenstream.reversed?.should_equal true
    @tokenstream.reverse!
    @tokenstream.reversed?.should_equal false
  end

  specify "Should provide a method that will convert a given token index so it will refer to the same token if the stream were reversed" do
    idx=@tokenstream.reverse_pos(2)
    @tokenstream.reverse.tokens[idx].should_equal @tokenstream.tokens[2]
  end
end
