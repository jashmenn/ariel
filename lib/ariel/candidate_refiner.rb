module Ariel
  
  # Given an array of candidate Rules, and an array of LabeledStreams,
  # allows heuristics to be applied to select the ideal Rule. All refine_* instance
  # methods will remove candidates from the internal candidates array.
  class CandidateRefiner

    attr_accessor :candidates
    def initialize(candidates, examples)
      @candidates=candidates.dup #Just in case we directly modify the array. Shouldn't happen.
      @examples=examples
    end

    # Selects only those candidates that match a given example in one of the
    # given ways (e.g. refiner.must_match seed_example, :early, :perfect).
    def must_match(example, *types)
      @candidates=@candidates.select {|rule| rule.matches(example, *types)}
      return @candidates
    end

    # Selects the Rule candidates that have the most matches of a given type
    # against the given examples. e.g. select_best_by_match_type(:early, :perfect)
    # will select the rules that have the most matches that are early or
    # perfect.
    def refine_by_match_type(*match_types)
      Log.debug "Refining by match types #{match_types.inspect}"
      return @candidates if @candidates.size==1
      @candidates = highest_scoring_by do |rule|
        rule_score=0
        @examples.each do |example|
          rule_score+=1 if rule.matches(example, *match_types)
        end
        rule_score #why doesn't return rule_score raise an error?
      end
      return @candidates
    end

    def refine_by_fewer_wildcards
      Log.debug "Refining to the rules with the fewest wildcards"
      @candidates = highest_scoring_by {|rule| -rule.wildcard_count} #hack or not?
      return @candidates
    end

    def refine_by_label_proximity
      Log.debug "Selecting rules that match the examples closest to the label"
      @candidates = highest_scoring_by do |rule|
        rule_score=0
        matched_examples=0
        @examples.each do |example|
          match_index = rule.closest_match(example)
          if match_index.nil?
            next
          else
            rule_score+= (example.label_index - match_index).abs
            matched_examples+=1
          end
        end
        rule_score = rule_score.to_f/matched_examples unless matched_examples==0 #mean distance from label_index
        -rule_score #So highest scoring = closest to label index.
      end
      return @candidates
    end

    def refine_by_longer_end_landmarks
      Log.debug "Selecting rules that have longer end landmarks"
      @candidates = highest_scoring_by {|rule| rule.landmarks.last.size unless rule.landmarks.last.nil?}
    end

    # Returns a random candidate. Meant for making the final choice in case
    # previous selections have still left multiple candidates.
    def random_from_remaining
      Log.debug "Selecting random from last #{candidates.size} candidate rules"
      @candidates.sort_by {rand}.first
    end

    private
    # All scoring functions use this indirectly. It iterates over each
    # Rule candidate, and assigns it a score in a hash of index:score pairs.
    # Each rule is yielded to the given block, which is expected to return that
    # rule's score.
    def score_by
      score_hash={}
      @candidates.each_with_index do |rule, index|
        score_hash[index]= yield rule
      end
      return score_hash
    end

    # Takes a scoring function as a block, and yields each rule to it. Returns
    # an array of the Rule candidates that have the highest score.
    def highest_scoring_by(&scorer)
      score_hash = score_by &scorer
      best_score = score_hash.values.sort.last
      highest_scorers=[]
      score_hash.each do |candidate_index, score|
        highest_scorers << @candidates[candidate_index] if score==best_score
      end
      Log.debug "#{highest_scorers.size} highest_scorers were found, with a score of #{best_score}"
      return highest_scorers
    end
  end
end
