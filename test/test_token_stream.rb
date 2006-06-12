require 'test/unit'
require 'ariel'

class TestTokenStream < Test::Unit::TestCase
  
  def setup
    @stream=Ariel::TokenStream.new
    @stream.tokenize("This is test101. See below:")
  end
  
  def test_advance
    assert_equal Ariel::Token.new("This", 0, 4), @stream.advance
  end

  def test_cur_pos
    assert_equal 0, @stream.cur_pos
    @stream.advance
    assert_equal 1, @stream.cur_pos
  end

  def test_each
    i=0
    @stream.each {i=i+1}
    assert_equal 8, i
    assert_equal 9, @stream.cur_pos
  end

  def test_rewind
    @stream.each {}
    @stream.rewind
    assert_equal 0, @stream.cur_pos
  end

  def test_skip_to
    assert @stream.skip_to("This")
    assert_equal 1, @stream.cur_pos  #Test the matched token has been consumed
    assert_nil @stream.skip_to("Ruby")
    assert_equal 1, @stream.cur_pos  #Stream's position remains unchanged by a failed match
    assert @stream.skip_to("See", "below")
    assert_equal 7, @stream.cur_pos
    @stream.rewind
    @stream.skip_to("test", :alpha_numeric)
    assert_equal 4, @stream.cur_pos
  end

  def test_tokenize
    assert_equal 8, @stream.length
    assert_equal 6, @stream.tokenize("Adding further tokens to the stream")
    @stream.clear
    @stream.tokenize("test")
    @stream.tokenize(":")
    assert_equal 4, @stream.last.start_loc  #Test the newly added token has the right offset
    @stream.tokenize("test", 50)
    assert_equal 50, @stream.last.start_loc  #Test a given offset is respected
  end

  def test_apply_rule
    assert_equal 3, @stream.apply_rule([["This", "is"], [:alpha]])
    assert_nil @stream.apply_rule([["Disco", "Duck"]])
  end
end

class TestLabeledStream < Test::Unit::TestCase
  def test_tokenize
    @stream=Ariel::LabeledStream.new
    @stream.tokenize("Extract Athis text", 9)
    assert_equal 2, @stream.label_index
  end

end
