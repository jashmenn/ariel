require 'rake'
require 'spec/rake/spectask'

Spec::Rake::SpecTask.new do |t|
  t.libs << "test"
  t.spec_files = FileList['./test/specs/*_spec.rb']
end

Spec::Rake::SpecTask.new do |t|
  t.name = :spec_v
  t.libs << "test"
  t.spec_files = FileList['./test/specs/*_spec.rb']
  t.spec_opts=['--format', 'specdoc']
end

