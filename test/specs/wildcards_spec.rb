require 'ariel'

context "When querying the Wildcards class" do

  specify "Should not be possible to create a Wildcards instance" do
    lambda {Ariel::Wildcards.new}.should_raise
  end

  specify "Should return a hash of Symbol to Regexp pairs when sent the list message" do
    wildcards=Ariel::Wildcards.list
    wildcards.should_be_a_kind_of Hash
    wildcards.keys.each {|key| key.should_be_a_kind_of Symbol}
    wildcards.values.each {|value| value.should_be_a_kind_of Regexp}
  end

  specify "When Wildcards.matching is called with a String, should return an array of the symbols of all matching wildcards" do
    Ariel::Wildcards.matching("Test").should_be_a_kind_of Array
    Ariel::Wildcards.matching("<a>").should_include :html_tag
  end

  specify "Should yield a symbol for every wildcard the string matches when Wildcards.matching is called" do
    list=[]
    Ariel::Wildcards.matching("<a>") {|wildcard| list << wildcard}
    list.should_not_be_empty
  end
end
