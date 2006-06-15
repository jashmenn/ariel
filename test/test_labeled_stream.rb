require 'test/unit'
require 'ariel'

class TestLabeledStream < Test::Unit::TestCase
  def setup
    @stream=Ariel::LabeledStream.new
    @stream.tokenize("Extract Athis text", 9)
  end

  def test_tokenize 
    assert_equal 2, @stream.label_index
    assert_equal 6, @stream.tokenize("Adding further tokens to the stream")
  end

  def test_reverse
    assert_equal 1, @stream.reverse.label_index
  end

  def test_reverse!
    assert @stream.reverse!
    assert_equal 1, @stream.label_index
  end


end
