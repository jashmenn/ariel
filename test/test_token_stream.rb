require 'ariel'
require 'ariel_test_case'

class TestTokenStream < Ariel::TestCase
  include Fixtures
  
  def setup
    @stream=Ariel::TokenStream.new
    @text = "This is test101. See below:"
    @stream.tokenize(@text)
    
    @labeled_stream = Ariel::TokenStream.new
    @labeled_stream.tokenize(@@labeled_document, true)
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
    @stream.skip_to(:anything, "below")
    assert_equal 7, @stream.cur_pos
  end

  def test_tokenize
    assert_equal 8, @stream.tokens.length
    @stream.each do |token|
      assert_equal @text[token.start_loc...token.end_loc], token.text
    end
    @labeled_stream.each do |token|
      assert_equal @@labeled_document[token.start_loc...token.end_loc], token.text
    end
  end

  def test_apply_rule
    assert_equal 3, @stream.apply_rule(Ariel::Rule.new(["This", "is"], [:alpha_numeric]))
    assert_nil @stream.apply_rule(Ariel::Rule.new(["Disco", "Duck"]))
    assert_equal 0, @stream.apply_rule(nil)
  end

  def test_set_label_at
    assert_raise(ArgumentError) {@stream.set_label_at 1}
    assert_nil @stream.label_index
    assert(@labeled_stream.set_label_at(16))
    assert_equal("The", @labeled_stream.tokens[@labeled_stream.label_index].text)
  end

  def test_raw_text
    assert_equal @text, @stream.raw_text
    assert_equal @@labeled_document.chomp, @labeled_stream.raw_text
  end

  def test_text
    assert_equal @text, @stream.text
    assert_equal @@unlabeled_document.chomp, @labeled_stream.text
  end

  def test_slice_by_token_index
    assert sliced=@stream.slice_by_token_index(1,3)
    assert_equal @text[sliced.tokens.first.start_loc...sliced.tokens.last.end_loc], sliced.text
  end
end
