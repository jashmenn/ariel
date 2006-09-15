module Ariel

  class RuleEvaluation
    include Comparable
    attr_reader :rule, :score

    def initialize(rule, examples)
      @rule=rule
      @examples=examples
      evaluate rule
    end

    def <=>(rule_evaluation)
      self.score <=> rule_evaluation.score
    end

    def evaluate(rule)
      p_matches=@examples.select {|example| rule.matches example, :early, :perfect}.size
      n_matches=@examples.select {|example| rule.matches example, :late}.size
      evaluation = (p_matches + 1).to_f/(p_matches + n_matches + 2)
      @score=evaluation
      return evaluation
    end
  end
end
