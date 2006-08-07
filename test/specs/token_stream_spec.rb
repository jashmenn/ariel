require 'ariel'
require 'fixtures'
include Fixtures

context "A new TokenStream" do
  setup do
    @tokenstream = Ariel::TokenStream.new
  end

  specify "Should return 0 when cur_pos is called" do
    @tokenstream.cur_pos.should_equal 0
  end

  specify "Should return an empty Array when tokens is called" do
    @tokenstream.tokens.should_be_a_kind_of Array
    @tokenstream.tokens.should_be_empty
  end

  specify "Should not contain any tokens" do
    @tokenstream.tokens.size.should_equal 0
  end

  specify "Should return an empty string went sent the message raw_text" do
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
end


