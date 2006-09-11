require 'ariel/tokenizer/custom'

module Ariel
  re_wanted = [
      Wildcards.list[:html_tag], # Match html tags that don't have attributes
      /\d+/, # Match any numbers, probably good to make a split
      /\b\w+\b/, # Pick up words, will split at punctuation
      /\S/ # Grab any characters left over that aren't whitespace
      ]
    re_labels = [LabelUtils.any_label_regex]
  Tokenizer::Default=Tokenizer::Custom.new(re_wanted, re_labels)
end
