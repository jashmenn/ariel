#!/usr/bin/env ruby

require 'ariel'
require 'optparse'
require 'yaml'

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

  opts.on('-d', '--dir=DIRECTORY', 'Destination directory') do |dir|
    options[:dir]=dir
  end

  opts.on('-S', '--structure=STRUCTURE', 'YAML file in which the structure is defined') do |structure|
    options[:structure]=structure
  end
end.parse!

case options[:mode]
when "learn"
  structure=YAML.load_file options[:structure]
  learnt_structure=Ariel::ExampleDocumentLoader.load_directory options[:src_dir], structure
  File.open(options[:structure], 'wb') do |file|
    YAML.dump(learnt_structure, file)
  end
  learnt_structure.each_descendant do |structure_node|
    puts structure_node.meta.name.to_s
    puts structure_node.ruleset.to_yaml
  end
when "extract"
  learnt_structure=YAML.load_file options[:structure]
  Dir.glob("#{options[:src_dir]}/*") do |file|
    tokenstream=Ariel::TokenStream.new
    tokenstream.tokenize File.read(file)
    root_node=Ariel::ExtractedNode.new :root, tokenstream, learnt_structure
    learnt_structure.apply_extraction_tree_on root_node
    puts "Results for #{file}:"
    root_node.each_descendant do |node|
      puts "#{node.meta.name}: #{node.tokenstream.text}"
    end
    puts
   # puts root_node.to_yaml
  end
end
