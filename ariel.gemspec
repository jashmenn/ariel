spec = Gem::Specification.new do |s|
  s.name = 'ariel'
  s.version = '0.1.0'
  s.summary = 'A Ruby Information Extraction Library'
  s.description = %{Ariel uses machine learning to assist in extracting information from semi-structured 
documents including (but not in any way limited to) web pages}
  s.author = 'A. S. Bradbury'
  s.email = 'asbradbury@gmail.com'
  s.homepage = 'http://ariel.rubyforge.org'
  s.rubyforge_project='ariel'
  
  s.has_rdoc=true
  s.extra_rdoc_files=['README', 'LICENSE']
  s.rdoc_options=['--main', 'README']
  s.executables = ['ariel']
  s.files = Dir['lib/**/*'] + Dir['test/**/*'] + s.extra_rdoc_files + Dir['examples/**/*'] + Dir['bin/*'] 
end
