require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "smugmug-sync"
    gem.summary = %Q{Download all your photos from SmugMug}
    gem.description = %Q{Download all your photos from the SmugMug photo sharing site. If you run it again, it will only download files which have changed (according to the MD5 hash)}
    gem.email = "simon@coles.to"
    gem.homepage = "http://github.com/simoncoles/smugmug-sync"
    gem.authors = ["Simon Coles"]
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    gem.add_dependency "smirk", ">= 0"
    gem.add_dependency "mechanize", ">= 0"
    gem.executable "smugmug-sync"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "smugmug-sync #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
