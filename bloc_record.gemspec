Gem::Specification.new do |s|
  s.name = 'bloc_record'
  s.version = '0.0.0'
  s.date = '2017-02-05'
  s.summary = 'BlocRecord ORM'
  s.description = 'An ActiveRecord-eque ORM adaptor'
  s.authors = ["Dustin Waggoner"]
  s.email = 'dustinwaggoner@comcast.net'
  s.files = Dir['lib/**/*.rb']
  s.require_paths = ["lib"]
  s.homepage = "https://rubygems.org/gems/bloc_record"
  s.license = 'MIT'
  s.add_runtime_dependency 'sqlite3', '~> 1.3'
  s.add_runtime_dependency 'pg', '~> 0.20.0'
  s.add_runtime_dependency 'activesupport'
end
