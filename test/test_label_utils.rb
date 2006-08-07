require 'ariel'
require 'ariel_test_case'

class TestLabelUtils < Ariel::TestCase
  include Fixtures

  def test_label_regex
    assert_equal 2, Ariel::LabelUtils.label_regex.uniq.size
    assert_kind_of Regexp, Ariel::LabelUtils.label_regex[0]
  end
  
  def test_clean_string
    assert_equal @@unlabeled_document, Ariel::LabelUtils.clean_string(@@labeled_document)
  end
end
