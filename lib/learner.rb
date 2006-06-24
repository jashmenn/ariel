module Ariel

  # Implements a fairly standard separate and conquer rule learning system.
  # Using a list of labeled examples, candidate rules are generated. A rule is
  # refined until it covers as many as possible of the labeled examples. This
  # rule is recorded, the covered examples are removed and the process repeats
  # on the remaining examples. Once all examples are covered, the disjunct of
  # all generated rules is returned.
  #
  # At least for now, rules consist of an array of arrays, e.g. [[:html_tag], ["This",
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
        set_seed
        @current_rule = find_best_rule() # Find the rule that matches the most examples and fails on the others/
        @examples.delete_if {|example| rule_covers?(example, rule)} #separate and conquer!
        rule << current_rule
      end
#      rule = order_rule(rule) #STALKER paper suggests that the generated rules should be ordered. This doesn't make sense, seeing as they are all generated based only on examples not matched by previous rules
      return rule
    end

    # The seed example is chosen from the array of remaining examples. The
    # LabeledStream with the fewest tokens before the labeled token is chosen.
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
      candidates = generate_initial_candidates
      begin
        best_refiner = get_best_refiner(candidates)
        best_solution = get_best_solution(candidates)
        @current_rule = best_refiner
        candidates = refine
      end while (is_not_perfect(best_solution) and best_refiner.empty? != true)
      return post_process best_solution
    end

    # Oversees both landmark (e.g. changing skip_to("<b>") in to
    # skip_to("Price","<b>") and topology (skip_to(:html_tag) to a chain of
    # skip_to() commands). Takes the current rule being generated and the
    # example against which it is being created (the current seed_rule) as
    # arguments. Only landmark refinements implemented for now. When adding new
    # landmarks, the algorithm 
    def refine
      topology_refs = []
      landmark_refs = []
      current_rule.each_with_index do |landmark, index|
        topology_refs.concat add_new_landmarks(landmark, index) #Topology refinements
        landmark_refs.concat lengthen_landmark(landmark, index) #Landmark refinements
      end
      return topology_refs + landmark_refs
    end

    # Implements landmark refinements. Landmarks are lengthened to make them
    # more specific. BROKEN
    # * Takes a landmark and its index in the current rule.
    # * Applies the rule consisting of all previous landmarks in the current
    #   rule, so the landmark can be considered in the context of the point from
    #   which it shall be applied.
    # * Every point at which the landmark matches after the cur_loc is considered.
    # * Two extended landmarks are generated - a landmark that includes the
    #   token before the match, and a landmark that includes that token after the
    #   match. 
    # * Rules are generated incorporating these extended landmarks, including
    #   alternative landmark extensions that use relevant wildcards.
    def lengthen_landmark(landmark, index)
      current_seed.rewind #In case apply_rule isn't called as index=0
      current_seed.apply_rule(current_rule[0..(index-1)]) if index > 0 #Don't care about already matched tokens
      landmark_refs=[]
      refined_rules=[]
      width = landmark.size
      while current_seed.skip_to(*landmark) #Probably should stop when cur_pos > label_index
        match_start = (current_seed.cur_pos - 1) - width #pos of first matched token
        match_end = current_seed.cur_pos - 1 #pos of last matched token
        preceding_token = current_seed[match_start-1]
        trailing_token = current_seed[match_end+1]
        (preceding_token.matching_wildcards << preceding_token.text).each do |front_extended_landmark|
          landmark_refs << landmark.clone.insert(0, front_extended_landmark)
        end
        (trailing_token.matching_wildcards << trailing_token.text).each do |back_extended_landmark|
          landmark_refs << landmark.clone.insert(-1, back_extended_landmark)
        end
        landmark_refs.each do |landmark|
          r=current_rule.clone
          r[index] = landmark #Replace portion of the rule with our refinement
          refined_rules << r
        end
      end
      return refined_rules
    end

    # Implements topology refinements - new landmarks are added to the current rule.
    # * Takes a landmark and its index in the current rule.
    # * Applies the rule consisting of all landmarks up to and including the
    #   current landmarkto find where it matches.
    # * Only tokens between the label_index and the position at which the partial rule matches are considered.
    # * Tokens before the rule match location will have no effect, as adding new
    #   landmarks before or after the current landmark will not make the rule
    #   match any earlier.
    # * For every token in this slice of the TokenStream, a new potential rule
    #   is created by adding a new landmark consisting of that token. This
    #   is also done for each of that token's matching wildcards.
    def add_new_landmarks(landmark, index)
      topology_refs=[]
      start_pos = current_seed.apply_rule(current_rule[0..index])
      end_pos = current_seed.label_index #No point adding tokens that occur after the label_index
      current_seed[start_pos...end_pos].to_a.each do |token| #Convert TokenStream slice to array for normal iteration
          topology_refs << current_rule.clone.insert(index+1, [token.text])
          token.matching_wildcards.each do |wildcard| #Creates *many* duplicate rules
            topology_refs << current_rule.clone.insert(index+1, [wildcard])
          end
      end
    return topology_refs.uniq
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
