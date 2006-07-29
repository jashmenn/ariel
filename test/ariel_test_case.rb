require 'test/unit'
require 'fixtures'

module Ariel
  include Fixtures
  class TestCase < Test::Unit::TestCase
    def run(result)
      debug "Running #{self.class.name}##{method_name}" unless method_name.to_s=="default_test"
      super
    end

    def default_test
    end
  end
end
