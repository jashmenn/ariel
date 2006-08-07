module Ariel

  # A RuleSet acts as a container for a StructureNode's start and end rules.
  # These are stored as an ordered array and are applied in turn until there is
  # a successful match. A RuleSet takes responsibility for applying start and
  # end rules to extract an ExtractedNode.
  class RuleSet
    def initialize(start_rules, end_rules)
      @start_rules=start_rules
      @end_rules=end_rules
    end

    def apply_to(tokenstream)
      tokenstream=extracted_node.tokenstream
      start_idx=nil
      end_idx=nil
      @start_rules.each do |rule|
        start_idx=rule.apply_to tokenstream
        break if start_idx
      end
      @end_rules.each do |rule|
        end_idx=rule.apply_to tokenstream
        break if end_idx
      end
      if start_idx && end_idx
        return nil if end_idx < start_idx
        return tokenstream.slice_by_token_index(start_idx, end_idx)
      else
        return nil
      end
    end
  end
end
