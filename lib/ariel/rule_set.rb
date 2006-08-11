module Ariel

  # A RuleSet acts as a container for a Node::Structure's start and end rules.
  # These are stored as an ordered array and are applied in turn until there is
  # a successful match. A RuleSet takes responsibility for applying start and
  # end rules to extract an Node::Extracted.
  class RuleSet
    def initialize(start_rules, end_rules)
      @start_rules=start_rules
      @end_rules=end_rules
    end

    # Returns an array of the extracted tokenstreams. An empty array is returned
    # if the rules cannot be applied.
    # TODO: Think more about the way list iteration rules are applied
    def apply_to(tokenstream)
      start_idxs=nil
      end_idxs=nil
      @start_rules.each do |rule|
        start_idxs=rule.apply_to tokenstream
        break if start_idxs
      end
      @end_rules.each do |rule|
        end_idxs=rule.apply_to tokenstream
        break if end_idxs
      end
      result=[]
      if start_idxs && end_idxs
        debug "RuleSet matched with start_idxs=#{start_idxs.inspect} and end_idxs=#{end_idxs.inspect}"
        start_idxs.zip(end_idxs) do |start_idx, end_idx|
          if start_idx && end_idx
            next if end_idx > start_idx
            result << tokenstream.slice_by_token_index(start_idx, end_idx)
            yield result.last if block_given?
          else
            break
          end
        end
      end
      return result
    end
  end
end
