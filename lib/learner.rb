module Ariel

  # Implements a fairly standard separate and conquer rule learning system.
  # Using a list of labeled examples, candidate rules are generated. A rule is
  # refined until it covers as many as possible of the labeled examples. This
  # rule is recorded, the covered examples are removed and the process repeats
  # on the remaining examples. Once all examples are covered, the disjunct of
  # all generated rules is returned.
  #
  # Temporarily, rules consist of an array of arrays, e.g. [[:html_tag], ["This",
  # "is"]] is equivalent to skip_to(:html_tag) followed by skip_to(["This",
  # "is"]).
  class Learner
    attr_accessor :current_rule, :current_seed
    # *examples is an array of LabeledStreams
    def initialize(*examples)
      @examples=examples
      @current_rule=[]
      set_seed
    end

    # Initiates the rule induction process.
    def learn_rule() 
      combined_rules=[]
      while not examples.empty?
        @current_rule = find_best_rule() # Find the rule that matches the most examples and fails on the others/
        @examples.delete_if {|example| rule_covers?(example, rule)} #separate and conquer!
        rule << current_rule
      end
#      rule = order_rule(rule) #STALKER paper suggests that the generated rules should be ordered. This doesn't make sense, seeing as they are all generated based only on examples not matched by previous rules
      return rule
    end

    # The seed example is chosen from the array of remaining examples. The
    # LabeledStream with the fewest tokens before the labeled token is chosed.
    def set_seed
      sorted = @examples.sort_by {|example| example.label_index}
      self.current_seed=sorted.first
      return current_seed
    end

    # Using the seed example passed to it, generates a list of initial rule
    # candidates for further refinement and evaluation. The Token prior to the
    # labeled token is considered, and separate rules are generated that skip_to that
    # token's text or any of it's matching wildcards.
    def generate_initial_candidates
      end_token=current_seed[current_seed.label_index-1]
      candidates=[]
      candidates<< [[end_token.text]] # A single rule takes the form [[landmarka, landmarkb], [landmarkc]]
      end_token.matching_wildcards.each {|wildcard| candidates<< [[wildcard]]}
      return candidates
    end

    # Equivalent of LearnDisjunct in STALKER algorithm. Generates initial
    # candidate rules, refines, and then returns a single rule.
    def find_best_rule
      raise NotImplmentedError
    end

    # Oversees both landmark (e.g. changing skip_to("<b>") in to
    # skip_to("Price","<b>") and topology (skip_to(:html_tag) to a chain of
    # skip_to() commands). Takes the current rule being generated and the
    # example against which it is being created (the current seed_rule) as
    # arguments. Only landmark refinements implemented for now. When adding new
    # landmarks, the algorithm 
    def refine
      candidates = []
      landmark_refs = []
      current_rule.each_with_index do |landmark_group, i|
        candidates.concat add_new_landmarks(landmark_group, i) #Topology refinements
        #Landmark refinements
        current_seed.rewind
        current_seed.apply_rule(current_rule[0..(i-1)]) unless current_rule.size == 1 #Don't care about already matched tokens
        p landmark_group
        width = landmark_group.size
        while current_seed.skip_to(*landmark_group) #Probably should stop when cur_pos > label_index
          match_start = (current_seed.cur_pos - 1) - width
          match_end = current_seed.cur_pos
          front_extended_landmark = landmark_group.clone.insert(0, current_seed[match_start-1].text)
          back_extended_landmark = landmark_group.clone.insert(-1, current_seed[match_start-1].text)
          #ToDo: Add matching wildcards in a non brain-dead way
          r1 = current_rule.clone
          r2 = current_rule.clone
          r1[i]=front_extended_landmark
          r2[i]=back_extended_landmark
          landmark_refs << r1
          landmark_refs << r2
        end
          
      end
      p candidates.uniq
      p landmark_refs
    end

    # Implements landmark refinements.
    def lengthen_landmarks()
      raise NotImplmentedError
    end

    # Implements topology refinements.
    def add_new_landmarks(landmark, index)
      rules=[]
      start_pos = current_seed.apply_rule(current_rule[0..index])
      end_pos = current_seed.label_index #No point adding tokens that occur after the label_index
      current_seed[start_pos...end_pos].to_a.each do |token| #Convert slice to array for normal iteration
          rules << current_rule.clone.insert(index+1, [token.text])
          token.matching_wildcards.each do |wildcard| #Creates *many* duplicate rules
            rules << current_rule.clone.insert(index+1, [wildcard])
          end
      end
    return rules
    end

    # A simple test function that returns true if the rule matches the given
    # example at all (irrespective of whether it is early or late).
    def rule_covers?(example, rule)
      return true if test_rule(example, rule)
      return false
    end


    # Given a LabeledStream and a rule, applies the rule on the stream and
    # returns nil if the match fails, :perfect_match if the match consumes all
    # tokens up to the labeled token, :early_match if it matches before the
    # labeled token and :late_match if the match is after the labeled token.
    def test_rule(example, rule)
      token_loc = example.apply_rule(rule)
      if token_loc == nil
        return nil
      elsif token_loc == example.label_index #Rule matches perfectly
        return :perfect_match
      elsif token_loc < example.label_index #Early match
        return :early_match
      elsif token_loc > example.label_index #Late match
        return :late_match
      end
    end
    
  end
  
end
