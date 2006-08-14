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
  r.list :version_history do |v|
    v.list_item :version
  end
end

File.open('structure.yaml', 'wb') do |file|
  YAML.dump structure, file
end
