module Ariel
  
  # Given an array of candidate Rules, allows heuristics to be applied to select
  # the ideal Rule.
  class CandidateSelector

    def initialize(candidates, examples)
      @candidates=candidates.clone #Just in case a CandidateSelector function directly modifies the array, affecting the original
      @examples=examples
    end

    def best_by_match_type(*match_types)
      return @candidates if @candidates.size==1
      score_hash={}
      @candidates.each_with_index do |rule, index|
        score_hash[index]=0
        @examples.each do |example|
          score_hash[index]+=1 if rule.matches(example, *match_types)
        end
      end
      best_score = score_hash.values.sort.last
      highest_scorers=[]
      score_hash.each do |candidate_index, score| 
        highest_scorers << @candidates[candidate_index] if score==best_score
      end
      @candidates = highest_scorers
    end

    # Returns a random candidate. Meant for making the final choice in case
    # previous selections have still left multiple candidates.
    def random_from_remaining
      @candidates.sort_by {rand}.first
    end
  end
end
