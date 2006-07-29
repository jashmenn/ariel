require 'ariel'
require 'ariel_test_case'

class TestLabelUtils < Ariel::TestCase
  include Fixtures

  def test_label_regex
    assert_not_equal Ariel::LabelUtils.label_regex(:open), Ariel::LabelUtils.label_regex(:closed)
    assert_kind_of Regexp, Ariel::LabelUtils.label_regex(:open)
  end
  
  def test_clean_string
    assert_equal @@unlabeled_document, Ariel::LabelUtils.clean_string(@@labeled_document)
  end

  def test_extract_label
    t1 = Ariel::LabelUtils.extract_label('title', @@labeled_document)
    t1.flatten!
    assert_equal @@labeled_document[t1[1]...t1[2]], t1[0]
    assert_equal "The test of the Century", t1[0]
    assert_nil Ariel::LabelUtils.extract_label('excerpt', @@labeled_document)
  end

  def test_count_labels
    assert_equal 4, Ariel::LabelUtils.count_labels(@@labeled_document)
    assert_equal 4, Ariel::LabelUtils.count_labels(@@labeled_document, :close)
  end
end
