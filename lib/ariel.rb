require 'token'
require 'token_stream'
require 'learner'
require 'node_like'
require 'extracted_node'
require 'structure_node'
require 'rule'
require 'wildcards'
require 'candidate_selector'
require 'label_utils'
require 'example_document_loader'

require 'breakpoint'
require 'logger'
  DEBUGLOG = Logger.new(File.open('debug.log', 'w'))
  DEBUGLOG.datetime_format = " \010"
  DEBUGLOG.progname = "\010\010\010"

  def debug(message)
    DEBUGLOG.debug message
  end
# = Ariel - A Ruby Information Extraction Library
module Ariel

end


