require 'ariel'
require 'yaml'

structure = Ariel::Node::Structure.new do |r|
  r.item :name
  r.item :current_version
  r.item :short_description
  r.item :category
  r.item :owner
  r.item :homepage
  r.item :license
  r.item :version_history
end

File.open('structure.yaml', 'wb') do |file|
  YAML.dump structure, file
end
