module Ariel

  require 'set'

  # Implements a fairly standard separate and conquer rule learning system.
  # Using a list of labeled examples, candidate rules are generated. A rule is
  # refined until it covers as many as possible of the labeled examples. This
  # rule is recorded, the covered examples are removed and the process repeats
  # on the remaining examples. Once all examples are covered, the disjunct of
  # all generated rules is returned.
  #
  # The methods are defined along the lines of the generic separate and 
  # conquer algorithm described in Furnkranz's review of seperate and conquer 
  # approaches: http://citeseer.ist.psu.edu/26490.html
  #
  # Alter the search strategy by modifying #generate_initial_candidates and 
  # #refine. Adjust the search algorithm through #select_candidates and 
  # #filter_rules, and the search heuristic through #evaluate_rule.
  #
  # Overfitting avoidance can be provided in #stopping_criterion_met?, 
  # #rule_stopping_criterion_met? or #post_process.

  class Learner
    attr_accessor :current_seed, :direction, :beam_width
    
    # Takes a list of TokenStreams containing labels.
    def initialize(*examples)
      if examples.any? {|example| example.label_index.nil?}
        raise ArgumentError, "Passed a TokenStream with no label"
      end
      Log.debug "New Learner instantiated with #{examples.size} labeled examples"
      @examples=examples
      @beam_width=1
    end

    # Initiates and operates the whole rule induction process. Finds an example
    # to use as its seed example, then finds a rule that matches the maximum
    # number of examples correctly and fails on all overs. All matched examples
    # are then removed and the process is repeated considering all examples that
    # remain. Returns an array of the rules found (in order). learn_rule will
    # take care of reversing the given examples if necessary.
    def learn_rule(direction, exhaustive=false)
      Log.debug "Searching for a #{direction} rule"
      @examples=@examples.collect {|tokenstream| Rule.prepare_tokenstream(tokenstream, direction)}
      @direction=direction
      @exhaustive=exhaustive
      remove_unsuitable_examples if exhaustive
      theory=[]
      while not @examples.empty?
        rule = find_best_rule
        break if rule_stopping_criterion_met?(theory, rule, @examples)
        remove_matched_examples(rule)
        theory << rule
      end
      theory=post_process(theory)
      Log.debug "Generated rules: #{theory.inspect}"
      Rule.clear_cache
      return theory
    end

    # Handles the generation of initial rules, then selects some candidates 
    # for further refinement. Each of these is refined, and the refinements 
    # are added to the list of rules. The list of rules is filtered and 
    # sorted, and processing continues untill a stopping criterion is met. The 
    # best_solution is returned.
    def find_best_rule
      set_seed
      rules={}
      rules=generate_initial_rules
      while not rules.empty?
        best_solution=get_best_solution(rules)
        break if stopping_criterion_met?(best_solution)
        candidates=[get_best_refiner(rules)]
        candidates.each do |candidate|
          refinements=refine(candidate)
          rules.concat refinements
        end
      end
      return best_solution
    end

    # Receives a hash of rule=>evaluation pairs and returns a subset of the 
    # best Rules as an array. Currently returns the top candidate.
    def select_candidates(rule_hash)
      candidates = rule_hash.keys.sort {|x, y| rule_hash[x] <=> rule_hash[y]}[0...beam_width]
      Log.debug "Going to refine #{candidates.inspect}"
      return candidates
    end

    # Not implemented for now. Returns true if no attempt should be made to 
    # learn more rules.
    def rule_stopping_criterion_met?(theory, best_rule, examples)
      false
    end

    # Returns true if no more refinement should take place
    def stopping_criterion_met?(best_solution)
      return false if best_solution.nil?
      if @exhaustive
        if perfect?(best_solution)
          return true
        end
      else
        return perfect?(best_solution)
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
    def get_best_refiner(rules)
      r=CandidateRefiner.new rules, @examples
      r.must_match current_seed, :early, :perfect 
      r.refine_by_match_type :early, :perfect #Discriminate on coverage
      r.refine_by_match_type :early
      r.refine_by_match_type :fail
      r.refine_by_fewer_wildcards
      r.refine_by_label_proximity
      r.refine_by_longer_end_landmarks
      best_refiner=r.random_from_remaining
      Log.debug "best_refiner found => #{best_refiner.inspect}"
      return best_refiner
    end

    # No post processing performed at the moment. Takes an array of the learnt 
    # rules so any further processing can take place.
    def post_process(theory)
      return theory
    end

    # Given a list of candidate rules, use heuristics to determine the best 
    # solution. Prefers:
    # * More correct matches
    # * More failed matches if a tie - failed matches preferable to incorrect 
    # matchees.
    # * Fewer tokens in SkipUntil()
    # * fewer wildcards
    # * longer end landmarks
    # * shorter unconsumed prefixes
    def get_best_solution(rules)
      r = CandidateRefiner.new(rules, @examples)
      r.refine_by_match_type :perfect
      r.refine_by_match_type :fail
      r.refine_by_fewer_wildcards
      r.refine_by_label_proximity
      r.refine_by_longer_end_landmarks
      best_solution = r.random_from_remaining
      Log.debug "best_solution found => #{best_solution.inspect}"
      return best_solution
    end    


    # Using the seed example passed to it, generates a list of initial rule
    # candidates for further refinement and evaluation. The Token prior to the
    # labeled token is considered, and separate rules are generated that skip_to that
    # token's text or any of it's matching wildcards.
    def generate_initial_rules
      initial_rules=[]
      if current_seed.label_index==0
        initial_rules << Rule.new([], @direction, @exhaustive)
      else
        end_token=current_seed.tokens[current_seed.label_index-1]
        Log.debug "Creating initial rules based on #{end_token.text}"
        initial_rules << Rule.new([[end_token.text]], @direction, @exhaustive)
        initial_rules.concat(initial_rules[0].generalise_feature(0))
        Log.debug "Initial rule candidates: #{initial_rules.inspect} created"
      end
      return initial_rules
    end

    # Oversees both landmark and topology refinements.  Takes the current rule 
    # being generated and the example against which it is being created (the 
    # current seed_rule) as arguments. 
    def refine(rule)
      refinements=[]
      rule.landmarks.each_with_index do |landmark, index|
        refinements.concat add_new_landmarks(rule, landmark, index) #Topology refinements
        refinements.concat lengthen_landmark(rule, landmark, index) #Landmark refinements
      end
      return refinements
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
    #
    # It's possible that some of the refined rules will no longer match, this 
    # is the case if two landmarks match only directly after each other, so 
    # when the first is lengthened, the rule as a whole no longer matches.
    def lengthen_landmark(rule, landmark, index)
      current_seed.rewind #In case apply_rule isn't called as index=0
      result = rule.partial(0..(index-1)).closest_match current_seed if index > 0 #ignore already matched
      return [] unless result # Rule doesn't match, no point refining
      refined_rules=[]
      width = landmark.size
      while current_seed.skip_to(*landmark)
        break if current_seed.cur_pos > current_seed.label_index
        match_start = (current_seed.cur_pos - 1) - width #pos of first matched token
        match_end = current_seed.cur_pos - 1 #pos of last matched token
        preceding_token = current_seed.tokens[match_start-1]
        trailing_token = current_seed.tokens[match_end+1]
        front_extended_landmark = landmark.clone.insert(0, preceding_token.text) if preceding_token
        back_extended_landmark = landmark.clone.insert(-1, trailing_token.text) if trailing_token
        f = rule.deep_clone
        b = rule.deep_clone
        f.landmarks[index] = front_extended_landmark if front_extended_landmark
        b.landmarks[index] = back_extended_landmark if back_extended_landmark
        refined_rules << f
        refined_rules.concat f.generalise_feature(index, 0)
        refined_rules << b
        refined_rules.concat b.generalise_feature(index, -1)
      end
      Log.debug "#{refined_rules.size} landmark refinements generated"
      return refined_rules
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
    #
    # As with #lengthen_landmark, it is possible for this method to generate 
    # rules that don't match.
    def add_new_landmarks(rule, landmark, index)
      topology_refs=[]
      start_pos = rule.partial(0..index).closest_match(current_seed, :early)
      end_pos = current_seed.label_index #No point adding tokens that occur after the label_index
      #assert { not start_pos.nil?}
      #assert {not end_pos.nil?}
      current_seed.tokens[start_pos...end_pos].each do |token|
        r=rule.deep_clone
        r.landmarks.insert(index+1, [token.text])
        topology_refs << r
        topology_refs.concat r.generalise_feature(index+1)
      end
      Log.debug "Topology refinements before uniq! #{topology_refs.size}"
      topology_refs.uniq!
      Log.debug "#{topology_refs.size} topology refinements generated"
      return topology_refs
    end


    private

    # The seed example is chosen from the array of remaining examples. The
    # LabeledStream with the fewest tokens before the labeled token is chosen.
    def set_seed
      sorted = @examples.sort_by {|example| example.label_index}
      self.current_seed=sorted.first
      Log.debug "current_seed=#{current_seed.text}"
      return current_seed
    end

    def remove_unsuitable_examples
      @examples.delete_if {|example| example_is_unsuitable?(example)}
      raise StandardError, "No examples are suitable for exhaustive rule learning" if @examples.empty?
    end

    # When learning list iteration rules, some examples may be unsuitable. For
    # instance if there is a list item at the start of an example with no tokens
    # before it, a skip_to(nil) start rule would be generated that wouldn't make
    # sense for exhaustive rules. The example should be caught by the
    # corresponding end rule. This should only be run after tokenstream's have
    # been prepared (reversed based on whether a :forward or :back rule is being
    # searched for). Only returns a valid conclusion if the examples are
    # intended to be used for exhaustive rule learning
    def example_is_unsuitable?(tokenstream)
      if tokenstream.label_index==0
        return true
      else
        return false
      end
    end

    # A given rule is perfect if it successfully matches the label on at least
    # one example and fails all others.
    def perfect?(rule)
      perfect_count=0
      fail_count=0
      @examples.each do |example|
        if rule.matches(example, :perfect)
          perfect_count+=1
        elsif rule.matches(example, :fail) 
          fail_count+=1
        end
      end
      if (perfect_count >= 1) && (fail_count == (@examples.size - perfect_count))
        Log.debug "Perfect rule found matching #{perfect_count} examples"
        return true
      else
        Log.debug "Rule was not perfect, perfect_count=#{perfect_count}, fail_count=#{fail_count}"
        return false
      end
    end

    def remove_matched_examples(rule)
      @examples.delete_if {|example| rule.apply_to(example)} #separate and conquer!
      Log.debug "Removing examples matched by the generated rule, #{@examples.size} remain"
    end
  end
end
