module Ariel

  # A rule contains an array of landmarks (each of which is an array of
  # individual landmark features. This landmark array is accessible through
  # Rule#landmarks. A Rule also has a direction :forward or :back, which
  # determines whether it is applied from the end or beginning of a tokenstream.
  class Rule
    attr_accessor :landmarks, :direction
    @@RuleMatchData=Struct.new(:token_loc, :type)
 
    # A rule's direction can be :back or :forward, which determines whether it
    # is applied from the start of end of the TokenStream. The landmark array
    # contains an array for each landmark, which consists of one or more
    # features. e.g. Rule.new(:forward, [[:anything, "Example"], ["Test"]]).
    def initialize(direction, landmarks=[])
      @landmarks=landmarks
      raise(ArgumentError, "Not a valid direction") unless [:forward, :back].include?(direction)
      @direction=direction
    end

    # Two rules are equal if they have the same list of landmarks
    def ==(rule)
      return (self.landmarks == rule.landmarks)
    end

    # Returns a rule that contains a given range of 
    def partial(range)
      return Rule.new(@direction, @landmarks[range])
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

    # Returns the number of wildcards included as features in the list of rule
    # landmarks.
    def wildcard_count
      @landmarks.flatten.select {|feature| feature.kind_of? Symbol}.size
    end

    # Given a TokenStream and a rule, applies the rule on the stream and
    # returns nil if the match fails and the token_loc if the match succeeds.
    # Yields a RuleMatchData Struct with accessors token_loc (the position of the match in the stream)
    # and type if a block is given. type is nil if the TokenStream has no label,
    # :perfect if all tokens up to the labeled token are consumed, :early if the rule's final position
    # is before the labeled token, and :late if it is after. The returned
    # token_loc is the position in the stream as it was passed in. That is, the
    # token_loc is always from the left of the given stream whether it is in a
    # reversed state or not.
    def apply_to(tokenstream)
      if tokenstream.reversed?
        target=tokenstream if @direction==:back
        target=tokenstream.reverse if @direction==:forward
      elsif not tokenstream.reversed?
        target=tokenstream if @direction==:forward
        target=tokenstream.reverse if @direction==:back
      end
      target.rewind #rules are applied from the beginning of the stream
      @landmarks.each do |landmark|
        unless target.skip_to(*landmark)
          return nil
        end
      end
      token_loc=target.cur_pos
      md = @@RuleMatchData.new(token_loc)
      if target.label_index
        idx = target.label_index
        md.type = :perfect if token_loc == idx
        md.type = :early if token_loc < idx
        md.type = :late if token_loc > idx
      end
      yield md if block_given?
      return token_loc
    end

    # Returns true or false depending on if the match of this rule on the given
    # tokenstream is of any of the given types (could be a combination of
    # :perfect, :early, :fail and :late). Only valid on streams with labels
    def matches(tokenstream, *types)
      raise ArgumentError, "No match types given" if types.empty?
      match = nil
      apply_to(tokenstream) {|md| match=md.type}
      match = :fail if match.nil?
      if types.include? match
        return true
      else
        return false
      end
    end
  end
end
