module Ariel

  # A rule contains an array of landmarks (each of which is an array of
  # individual landmark features. This landmark array is accessible through
  # Rule#landmarks. A Rule also has a direction :forward or :back, which
  # determines whether it is applied from the end or beginning of a tokenstream.
  class Rule
    attr_accessor :landmarks, :direction
    @@RuleMatchData=Struct.new(:token_loc, :type)
    def initialize(*landmarks)
      @landmarks=landmarks
    end

    def ==(rule)
      return (self.landmarks == rule.landmarks)
    end

    def partial(range)
      return Rule.new(*@landmarks[range])
    end

    def deep_clone
      Marshal::load(Marshal.dump(self))
    end

    def generalise_feature(landmark_index, feature_index=0)
      feature=self.landmarks[landmark_index][feature_index]
      alternates=[]
      Wildcards.matching(feature) do |wildcard|
        r=self.deep_clone
        r.landmarks[landmark_index][feature_index]=wildcard
        alternates << r
        yield r if block_given?
      end
      return alternates
    end

    def wildcard_count
      @landmarks.flatten.select {|feature| feature.kind_of? Symbol}.size
    end

    # Given a TokenStream and a rule, applies the rule on the stream and
    # returns nil if the match fails. Returns a RuleMatchData Struct with
    # accessors token_loc (the position of the match in the stream) and
    # type. type is nil if the TokenStream has no label, :perfect if all tokens
    # up to the labeled token are consumed, :early if the rule's final position
    # is before the labeled token, and :late if it is after.
    def apply_to(tokenstream)
      token_loc = tokenstream.apply_rule(self)
      return nil unless token_loc
      md = @@RuleMatchData.new(token_loc)
      if tokenstream.respond_to? :label_index
        idx = tokenstream.label_index
        md.type = :perfect if token_loc == idx
        md.type = :early if token_loc < idx
        md.type = :late if token_loc > idx
      end
      return md
    end

    def matches(tokenstream, *types)
      match = apply_to(tokenstream)
      return false unless match or types.include? :fail
      return true if match==nil and types.include? :fail #Special case when we want :fail match
      return true if types.empty? #There was a match, don't care what type
      return true if types.include? match.type #Match matches one of the given types
      return false #Matched, but wasn't the given type
    end

  end
end
