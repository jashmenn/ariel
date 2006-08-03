#!/usr/bin/env ruby

require 'ariel'
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: #$0 [mode] [options]"

  opts.on('-m', '--mode=mode') do |mode|
    raise OptionParser::InvalidArgument unless (mode=="extract" or mode=="learn")
    options[:mode]=mode
  end

  opts.on('-s', '--src-dir=DIRECTORY', 'Source directory') do |src_dir|
    options[:src_dir]=src_dir 
  end

#  opts.on('-d', '--dir=DIRECTORY', 'Destination directory') do |dir|
#    options[:dir]=dir
#  end
end.parse!

load File.join(options[:src_dir], "structure.rb")
raise StandardError unless (defined? @structure)
case options[:mode]
when "extract"

