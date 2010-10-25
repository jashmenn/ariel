require 'rake'
require 'spec/rake/spectask'

# works with rspec 0.6.2, ruby 1.9.1

Spec::Rake::SpecTask.new do |t|
  t.libs << "test"
  t.spec_files = FileList['./test/specs/*_spec.rb']
end

Spec::Rake::SpecTask.new do |t|
  t.name = :spec_v
  t.libs << "test"
  t.libs << "lib"
  t.spec_files = FileList['./test/specs/*_spec.rb']
  t.spec_opts=['--format', 'specdoc']
end

