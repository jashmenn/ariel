require 'ariel/log'
require 'ariel/wildcards'
require 'ariel/label_utils'
require 'ariel/token'
require 'ariel/tokenizer/default'
require 'ariel/token_stream'
require 'ariel/learner'
require 'ariel/node/structure'
require 'ariel/node/extracted'
require 'ariel/rule'
require 'ariel/rule_evaluation'
require 'ariel/candidate_refiner'
require 'ariel/labeled_document_loader'
require 'ariel/rule_set'

#require 'breakpoint'
# = Ariel - A Ruby Information Extraction Library
# Ariel intends to assist in extracting information from semi-structured
# documents including (but not in any way limited to) web pages. Although you
# may use libraries such as Hpricot or Rubyful Soup, or even plain Regular
# Expressions to achieve the same goal, Ariel approaches the problem very
# differently. Ariel relies on the user labeling examples of the data they
# want to extract, and then finds patterns across several such labeled
# examples in order to produce a set of general rules for extracting this
# information from any similar document.
#
# When working with Ariel, your workflow might look something like this:
# 1. Define a structure for the data you wish to extract. For example:
#
#     @structure = Ariel::StructureNode.new do |r|
#       r.item :article do |a|
#         a.item :title
#         a.item :author
#         a.item :date
#         a.item :body
#       end
#       r.list :comments do |c|
#         c.list_item :comment do |c|
#           c.item :author
#           c.item :date
#           c.item :body
#         end
#       end
#     end
# 2. Label these fields in a few example documents (normally at least 3).
#    Labels are in the form of <tt><l:label_name>...</l:label_name></tt>
# 3. Ariel will read these examples, and try to generate suitable rules that can
#    be used to extract this data from other similarly structured documents. Use
#    Ariel#learn to initiate learn ruling.
# 4. A wrapper has been generated - we can now happily load documents with the
#    same structure (normally documents generated by the same rules, so
#    different pages from a single site perhaps) and query the extracted data.
#    See Ariel#extract.
module Ariel

  class << self
    # Given a root Node::Structure and a list of labeled_files (either IO objects
    # or strings representing files that can be opened with File.read, will learn
    # rules using the labeled examples. The passed Node::Structure tree is
    # returned with new RuleSets added containing the learnt rules. This structure
    # can now be used with Ariel#extract on unlabeled documents.
    #
    # <tt>Ariel.learn structure, 'file1.html', fileobj, 'file2.html'</tt>
    def learn(structure, *labeled_files)
      raise ArgumentError, "Passed structure is not the parent of the document tree" unless structure.parent.nil?
      labeled_strings=collect_strings(labeled_files)
      return LabeledDocumentLoader.supervise_learning(structure, *labeled_strings)
    end

    # Will use the given root Node::Structure to extract information from each of
    # the given files (can be any object responding to #read, and if passed a
    # string the parameter will be opened using File.read). If a block is given,
    # each root Node::Extracted is yielded. An array of each root extracted node
    # is returned.
    #
    # <tt>Ariel.extract structure, 'file1.txt', fileobj, 'file2.html'  # =></tt> an
    # array of 3 Node::Extracted objects
    def extract(structure, *files_to_extract)
      raise ArgumentError, "Passed structure is not the parent of the document tree" unless structure.parent.nil?
      extractions=[]
      collect_strings(files_to_extract).each do |string|
        tokenstream = TokenStream.new
        tokenstream.tokenize string
        root_node=Ariel::Node::Extracted.new :root, tokenstream, structure
        structure.apply_extraction_tree_on root_node
        extractions << root_node
        yield root_node if block_given?
      end
      return extractions
    end

    private
    def collect_strings(files)
      strings=[]
      files.each do |file|
        if file.kind_of? String
          next unless File.file? file
          strings << File.read(file)
        elsif file.respond_to? :read
          strings << file.read
        else
          raise ArgumentError, "Don't know how to handle #{file.inspect}"
        end
      end
      return strings
    end
  end
end


