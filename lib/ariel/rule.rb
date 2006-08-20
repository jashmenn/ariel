module Ariel

  # A rule contains an array of landmarks (each of which is an array of
  # individual landmark features. This landmark array is accessible through
  # Rule#landmarks. A Rule also has a direction :forward or :back, which
  # determines whether it is applied from the end or beginning of a tokenstream.
  class Rule
    attr_accessor :landmarks, :direction, :exhaustive
    @@RuleMatchData=Struct.new(:token_loc, :type)
    @@cache={}

    # A rule's direction can be :back or :forward, which determines whether it
    # is applied from the start of end of the TokenStream. The landmark array
    # contains an array for each landmark, which consists of one or more
    # features. e.g. Rule.new([[:anything, "Example"], ["Test"]], :forward).
    def initialize(landmarks, direction, exhaustive=false)
      @landmarks=landmarks
      raise(ArgumentError, "Not a valid direction") unless [:forward, :back].include?(direction)
      @direction=direction
      @exhaustive=exhaustive
    end

    def exhaustive?
      @exhaustive
    end

    # Two rules are equal if they have the same list of landmarks and the same
    # direction
    def ==(rule)
      return ((self.landmarks == rule.landmarks) && self.direction==rule.direction)
    end
    alias :eql? :==

    def hash
      [@landmarks, @direction, @exhaustive].hash
    end

    # Returns a rule that contains a given range of 
    def partial(range)
      return Rule.new(@landmarks[range], @direction)
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
    # returns an empty array if the match fails and an array of token_locs if the match succeeds.
    # Yields a RuleMatchData Struct with accessors token_loc (the position of the match in the stream)
    # and type if a block is given. type is nil if the TokenStream has no label,
    # :perfect if all tokens up to the labeled token are consumed, :early if the rule's final position
    # is before the labeled token, and :late if it is after. The returned
    # token_loc is the position in the stream as it was passed in. That is, the
    # token_loc is always from the left of the given stream whether it is in a
    # reversed state or not.
    def apply_to(tokenstream) 
      target=self.class.prepare_tokenstream(tokenstream, @direction)
      cache_check=@@cache[[tokenstream.cache_hash, self.hash]]
      if cache_check
        token_locs=cache_check
      else
        token_locs=[]
        while result=seek_landmarks(target)
          token_locs << correct_match_location(tokenstream, result)
          break unless exhaustive?
        end
        @@cache[[tokenstream.cache_hash, self.hash]]=token_locs
      end
      if block_given?
        generate_match_data(target, token_locs).each {|md| yield md}
      end
      return token_locs
    end

    # Returns true or false depending on if the match of this rule on the given
    # tokenstream is of any of the given types (could be a combination of
    # :perfect, :early, :fail and :late). Only valid on streams with labels
    def matches(tokenstream, *types)
      raise ArgumentError, "No match types given" if types.empty?
      raise ArgumentError, "Only applicable to tokenstreams containing a label" if tokenstream.label_index.nil?
      match = nil
      apply_to(tokenstream) {|md| match=md.type if md.type;}
      match = :fail if match.nil?
      if types.include? match
        return true
      else
        return false
      end
    end

    # Only used in rule learning on labeled tokenstreams. Needed to provide the
    # match index most relevant to the currently labeled list item. A preference
    # of :early or :late can be passed, which will only return a
    # token_loc before the stream's label_index or after the label_index.
    def closest_match(tokenstream, preference=:none)
      token_locs=self.apply_to(tokenstream)
      return find_closest_match(token_locs, tokenstream.label_index)
    end

    # Reverses the given tokenstream if necessary based on its current direction, and
    # the direction given (corresponding to the sort of rule you hope to apply
    # to it). 
    def self.prepare_tokenstream(tokenstream, direction)
      if tokenstream.reversed?
        target=tokenstream if direction==:back
        target=tokenstream.reverse if direction==:forward
      elsif not tokenstream.reversed?
        target=tokenstream if direction==:forward
        target=tokenstream.reverse if direction==:back
      end
      target.rewind #rules are applied from the beginning of the stream
      return target
    end

    private

    # Finds the sequence of landmarks contained in the Rule instance in the
    # given tokenstream. The logic of reversing or rewinding the stream if necessary
    # is left to the method that uses it. Returns the match location from the
    # beginning of whatever tokenstream it was passed. This location should be
    # corrected by correct_match_location
    def seek_landmarks(tokenstream)
      @landmarks.each do |landmark|
        unless tokenstream.skip_to(*landmark)
          return nil
        end
      end
      return tokenstream.cur_pos
    end

    # Takes the original tokenstream passed to apply_to and reverses the match
    # location is required, so the match location returned to the user will be
    # the index from the left of the passed tokenstream.
    def correct_match_location(tokenstream, match_loc)
      if tokenstream.reversed?
        result=match_loc if @direction==:back
        result=tokenstream.reverse_pos(match_loc) if @direction==:forward
      elsif not tokenstream.reversed?
        result=match_loc if @direction==:forward
        result=tokenstream.reverse_pos(match_loc) if @direction==:back
      end
      return result
    end

    def generate_match_data(tokenstream, token_locs)
      result=[]
      if tokenstream.label_index
        closest_match=find_closest_match(token_locs, tokenstream.label_index)
      end
      token_locs.each do |token_loc|
        md = @@RuleMatchData.new(token_loc)
        if tokenstream.label_index && token_loc==closest_match
          idx = tokenstream.label_index
          md.type = :perfect if token_loc == idx
          md.type = :early if token_loc < idx
          md.type = :late if token_loc > idx
        end
        result << md
      end
      return result
    end

    def find_closest_match(token_locs, label_index, preference=:none)
      if preference==:early
        token_locs = token_locs.reject {|token_loc| token_loc > label_index}
      elsif preference==:late
        token_locs = token_locs.reject {|token_loc| token_loc | label_index}
      end
      token_locs.sort_by {|token_loc| (label_index-token_loc).abs}.first
    end
  end
end
