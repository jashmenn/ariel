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
    attr_accessor :current_rule, :current_seed, :candidates
    # *examples is an array of LabeledStreams
    def initialize(*examples)
      @examples=examples
      @current_rule=Rule.new
      @candidates=[]
      set_seed
    end

    # Initiates the rule induction process.
    def learn_rule() 
      combined_rules=[]
      while not @examples.empty?
        set_seed
        rule = find_best_rule() # Find the rule that matches the most examples and fails on the others/
        @examples.delete_if {|example| rule.matches(example)} #separate and conquer!
        combined_rules << rule
      end
#      rule = order_rule(rule) #STALKER paper suggests that the generated rules should be ordered. This doesn't make sense, seeing as they are all generated based only on examples not matched by previous rules
      return combined_rules
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
      @candidates<< Rule.new([end_token.text])
      end_token.matching_wildcards.each {|wildcard| @candidates<< Rule.new([wildcard])}
      return @candidates.size
    end

    # Equivalent of LearnDisjunct in STALKER algorithm. Generates initial
    # candidate rules, refines, and then returns a single rule.
    def find_best_rule
      generate_initial_candidates
      begin
        best_refiner = get_best_refiner
        best_solution = get_best_solution
        @current_rule = best_refiner
        refine
      end while (is_not_perfect(best_solution) and best_refiner.empty? != true) #is an infinite loop possible?
#     return post_process(best_solution)
      return best_solution
    end

    def is_not_perfect(rule)
      @examples.each do |example|
        return true unless rule.matches(example, :perfect, :fail)
      end
      return false
    end

    # Given a list of candidate rules, uses heuristics to determine a rule
    # considered to be the best refiner. Prefers candidate rules that have:
    # * Larger coverage = early + correct matches.
    # * If equal, prefer more early matches - can be made in to fails or perfect matches.
    #   Intuitively, if there are more equal matches the rule is finding features common to all documents.
    # * If there is a tie, more failed matches wins - we want matches to fail rather than match incorrectly
    # * Fewer wildcards - more specific, less likely to match by chance.
    # * Shorter unconsumed prefixes - closer to matching correctly
    # * fewer tokens in SkipUntil() - huh? Perhaps because skip_until relies on slot content rather than
    #   document structure.
    # * longer end landmarks - prefer "local context" landmarks.
    def get_best_refiner
      selector = CandidateSelector.new(@candidates, @examples)
      selector.best_by_match_type :early, :perfect #Discriminate on coverage
      selector.best_by_match_type :early
      selector.best_by_match_type :fail
#     selector.fewer_wildcards
#     selector.closest_to_label
#     selector.longer_end_landmarks
      best_refiner = selector.random_from_remaining #just pick a random one for now if still multiple
      return best_refiner
    end

    # Given a list of candidate rules, use heuristics to determine the best solution. Prefers:
    # * More correct matches
    # * More failed matches if a tie - failed matches preferable to incorrect matchees.
    # * Fewer tokens in SkipUntil()
    # * fewer wildcards
    # * longer end landmarks
    # * shorter unconsumed prefixes
    def get_best_solution
      selector = CandidateSelector.new(@candidates, @examples)
      selector.best_by_match_type :perfect
      selector.best_by_match_type :fail
#     selector.fewer_wildcards
#     selector.closest_to_label
#     selector.longer_end_landmarks
      best_solution = selector.random_from_remaining
      return best_solution
    end    

    # Oversees both landmark (e.g. changing skip_to("<b>") in to
    # skip_to("Price","<b>") and topology (skip_to(:html_tag) to a chain of
    # skip_to() commands). Takes the current rule being generated and the
    # example against which it is being created (the current seed_rule) as
    # arguments. Only landmark refinements implemented for now. When adding new
    # landmarks, the algorithm 
    def refine
      @candidates=[]
      current_rule.landmarks.each_with_index do |landmark, index|
        add_new_landmarks(landmark, index) #Topology refinements
        lengthen_landmark(landmark, index) #Landmark refinements
      end
      return @candidates.size
    end

    # Implements landmark refinements. Landmarks are lengthened to make them
    # more specific.
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
      current_seed.apply_rule(current_rule.partial(0..(index-1))) if index > 0 #Don't care about already matched tokens
      refined_rules=[]
      width = landmark.size
      while current_seed.skip_to(*landmark) #Probably should stop when cur_pos > label_index
        match_start = (current_seed.cur_pos - 1) - width #pos of first matched token
        match_end = current_seed.cur_pos - 1 #pos of last matched token
        preceding_token = current_seed[match_start-1]
        trailing_token = current_seed[match_end+1]
        front_extended_landmark = landmark.clone.insert(0, preceding_token.text) if preceding_token
        back_extended_landmark = landmark.clone.insert(-1, trailing_token.text) if trailing_token
        f = current_rule.deep_clone
        b = current_rule.deep_clone
        f.landmarks[index] = front_extended_landmark if front_extended_landmark
        b.landmarks[index] = back_extended_landmark if back_extended_landmark
        refined_rules << f
        refined_rules.concat f.generalise_feature(index, 0)
        refined_rules << b
        refined_rules.concat b.generalise_feature(index, -1)
      end
      @candidates.concat refined_rules
      return refined_rules.size
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
      start_pos = current_seed.apply_rule(current_rule.partial(0..index))
      end_pos = current_seed.label_index #No point adding tokens that occur after the label_index
      current_seed[start_pos...end_pos].to_a.each do |token| #Convert TokenStream slice to array for normal iteration
          r=current_rule.deep_clone
          r.landmarks.insert(index+1, [token.text])
          topology_refs << r
          topology_refs.concat r.generalise_feature(index+1)
      end
    topology_refs.uniq!
    @candidates.concat topology_refs
    return topology_refs.size
    end
  end
end
