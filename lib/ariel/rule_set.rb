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
        break if !start_idxs.empty?
      end
      @end_rules.each do |rule|
        end_idxs=rule.apply_to tokenstream
        end_idxs.reverse! #So the start_idxs and end_idxs match up
        break if !end_idxs.empty?
      end
      result=[]
      unless start_idxs.empty? && end_idxs.empty?
        # Following expression deals with the case where the first start rule
        # matches after the first end rule, indicating that all tokens up to the
        # end rule match should be a list item
        if start_idxs.first > end_idxs.first
          start_idxs.insert(0, 0)
        end
        if end_idxs.last < start_idxs.last
          end_idxs << (tokenstream.size - 1)
        end
        Log.debug "RuleSet matched with start_idxs=#{start_idxs.inspect} and end_idxs=#{end_idxs.inspect}"
        start_idxs.zip(end_idxs) do |start_idx, end_idx|
          if start_idx && end_idx
            next if start_idx > end_idx
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
