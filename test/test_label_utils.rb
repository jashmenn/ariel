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
end
