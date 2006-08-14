require 'ariel'
require 'yaml'

structure = Ariel::Node::Structure.new do |r|
  r.item :calculation do |c|
    c.item :result
  end
end

File.open('structure.yaml', 'w') do |file|
  YAML.dump structure, file
end
