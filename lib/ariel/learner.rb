module Ariel

  # Implements a fairly standard separate and conquer rule learning system.
  # Using a list of labeled examples, candidate rules are generated. A rule is
  # refined until it covers as many as possible of the labeled examples. This
  # rule is recorded, the covered examples are removed and the process repeats
  # on the remaining examples. Once all examples are covered, the disjunct of
  # all generated rules is returned.

  class Learner
    attr_accessor :current_rule, :current_seed, :candidates, :direction
    
    # Takes a list of TokenStreams containing labels.
    def initialize(*examples)
      if examples.any? {|example| example.label_index.nil?}
        raise ArgumentError, "Passed a TokenStream with no label"
      end
      debug "ATTENTION: New Learner instantiated with #{examples.size} labeled examples"
      @examples=examples
      @candidates=[]
      set_seed
    end

    # Initiates and operates the whole rule induction process. Finds an example
    # to use as its seed example, then finds a rule that matches the maximum
    # number of examples correctly and fails on all overs. All matched examples
    # are then removed and the process is repeated considering all examples that
    # remain. Returns an array of the rules found (in order).
    def learn_rule(direction, exhaustive=false)
      debug "Searching for a #{direction} rule"
      @direction=direction
      @exhaustive=exhaustive
      @current_rule=Rule.new(direction, [], exhaustive)
      combined_rules=[]
      while not @examples.empty?
        set_seed unless @examples.include? @current_seed
        rule = find_best_rule() # Find the rule that matches the most examples and fails on the others
        prev_size = @examples.size
        @examples.delete_if {|example| rule.apply_to(example)} #separate and conquer!
        debug "Removing #{prev_size - @examples.size} examples matched by the generated rule, #{@examples.size} remain"
        combined_rules << rule
      end
#      rule = order_rule(rule) #STALKER paper suggests that the generated rules should be ordered. This doesn't make sense, seeing as they are all generated based only on examples not matched by previous rules
      debug "Generated rules: #{combined_rules.inspect}"
      return combined_rules
    end

    # The seed example is chosen from the array of remaining examples. The
    # LabeledStream with the fewest tokens before the labeled token is chosen.
    def set_seed
      sorted = @examples.sort_by {|example| example.label_index}
      self.current_seed=sorted.first
      debug "current_seed=#{current_seed.text}"
      return current_seed
    end

    # Using the seed example passed to it, generates a list of initial rule
    # candidates for further refinement and evaluation. The Token prior to the
    # labeled token is considered, and separate rules are generated that skip_to that
    # token's text or any of it's matching wildcards.
    def generate_initial_candidates
      if current_seed.label_index==0
        @candidates << Rule.new(@direction, [], @exhaustive)
      else
        end_token=current_seed.tokens[current_seed.label_index-1]
        debug "Creating initial candidates based on #{end_token.text}"
        @candidates<< Rule.new(@direction, [[end_token.text]], @exhaustive)
        @candidates.concat(@candidates[0].generalise_feature(0))
        debug "Initial candidates: #{@candidates.inspect} created"
      end
      return @candidates.size
    end

    # Equivalent of LearnDisjunct in STALKER algorithm. Generates initial
    # candidate rules, refines, and then returns a single rule.
    def find_best_rule
      @candidates=[]
      generate_initial_candidates
      while true
        best_refiner = get_best_refiner
        best_solution = get_best_solution
        @current_rule = best_refiner
        break if perfect?(best_solution)
        refine
      end
#     return post_process(best_solution)
      debug "Rule found: #{best_solution.inspect}"
      return best_solution
    end

    # A given rule is perfect if it successfully matches the label on at least
    # one example and fails all others.
    def perfect?(rule)
      perfect_count=0
      fail_count=0
      @examples.each do |example|
        if rule.matches(example, :perfect)
          perfect_count+=1
          debug "#{rule.inspect} matches #{example.text} perfectly"
        elsif rule.matches(example, :fail) 
          fail_count+=1
          debug "#{rule.inspect} fails to match #{example.text}"
        end
      end
      if (perfect_count >= 1) && (fail_count == (@examples.size - perfect_count))
        return true
      else
        debug "Rule was not perfect, perfect_count=#{perfect_count}, fail_count=#{fail_count}"
        return false
      end
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
      r = CandidateRefiner.new(@candidates, @examples)
      r.refine_by_match_type :early, :perfect #Discriminate on coverage
      r.refine_by_match_type :early
      r.refine_by_match_type :fail
      r.refine_by_fewer_wildcards
      r.refine_by_label_proximity
      r.refine_by_longer_end_landmarks
      best_refiner = r.random_from_remaining #just pick a random one for now if still multiple
      debug "best_refiner found => #{best_refiner.inspect}"
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
      r = CandidateRefiner.new(@candidates, @examples)
      r.refine_by_match_type :perfect
      r.refine_by_match_type :fail
      r.refine_by_fewer_wildcards
      r.refine_by_label_proximity
      r.refine_by_longer_end_landmarks
      best_solution = r.random_from_remaining
      debug "best_solution found => #{best_solution.inspect}"
      return best_solution
    end    

    # Oversees both landmark (e.g. changing skip_to("<b>") in to
    # skip_to("Price","<b>") and topology (skip_to(:html_tag) to a chain of
    # skip_to() commands). Takes the current rule being generated and the
    # example against which it is being created (the current seed_rule) as
    # arguments. 
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
      result = @current_rule.partial(0..(index-1)).closest_match current_seed if index > 0 #Don't care about already matched tokens
      return 0 unless result # Rule doesn't match, no point refining
      refined_rules=[]
      width = landmark.size
      while current_seed.skip_to(*landmark) #Probably should stop when cur_pos > label_index
        break if current_seed.cur_pos > current_seed.label_index
        match_start = (current_seed.cur_pos - 1) - width #pos of first matched token
        match_end = current_seed.cur_pos - 1 #pos of last matched token
        preceding_token = current_seed.tokens[match_start-1]
        trailing_token = current_seed.tokens[match_end+1]
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
      debug "#{refined_rules.size} landmark refinements generated"
      return refined_rules.size
    end

    # Implements topology refinements - new landmarks are added to the current rule.
    # * Takes a landmark and its index in the current rule.
    # * Applies the rule consisting of all landmarks up to and including the
    #   current landmark to find where it matches.
    # * Only tokens between the label_index and the position at which the partial rule matches are considered.
    # * Tokens before the rule match location will have no effect, as adding new
    #   landmarks before or after the current landmark will not make the rule
    #   match any earlier.
    # * For every token in this slice of the TokenStream, a new potential rule
    #   is created by adding a new landmark consisting of that token. This
    #   is also done for each of that token's matching wildcards.
    def add_new_landmarks(landmark, index)
      topology_refs=[]
      start_pos = current_rule.partial(0..index).closest_match(current_seed, :early)
      end_pos = current_seed.label_index #No point adding tokens that occur after the label_index
      current_seed.tokens[start_pos...end_pos].each do |token|
          r=current_rule.deep_clone
          r.landmarks.insert(index+1, [token.text])
          topology_refs << r
          topology_refs.concat r.generalise_feature(index+1)
      end
    debug "Topology refinements before uniq! #{topology_refs.size}"
    topology_refs.uniq!
    @candidates.concat topology_refs
    debug "#{topology_refs.size} topology refinements generated"
    return topology_refs.size
    end
  end
end
