$LOAD_PATH.push File.expand_path('../lib', __FILE__)

version = File.read(File.join(File.dirname(__FILE__), 'VERSION')).strip

Gem::Specification.new do |s|
  s.name = 'xip'
  s.summary = 'Ruby framework for conversational bots'
  s.description = 'Ruby framework for building conversational bots.'
  s.homepage = 'https://github.com/xipkit/xip'
  s.licenses = ['MIT']
  s.version = version
  s.authors = ['Mauricio Gomes']
  s.email = 'mauricio@edge14.com'

  s.add_dependency 'sinatra', '~> 2.0'
  s.add_dependency 'puma', '~> 5.2'
  s.add_dependency 'thor', '~> 1.1'
  s.add_dependency 'multi_json', '~> 1.12'
  s.add_dependency 'sidekiq', '~> 6.0'
  s.add_dependency 'activesupport', '~> 6.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
end
