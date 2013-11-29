# -*- encoding : utf-8 -*-
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "imml"
    gem.summary = %Q{immatériel.fr IMML parser/writer}
    gem.description = %Q{immatériel.fr IMML parser/writer}
    gem.email = "jboulnois@immateriel.fr"
    gem.homepage = "http://github.com/immateriel/imml"
    gem.authors = ["julbouln"]
    gem.files = Dir.glob('bin/**/*') + Dir.glob('lib/**/*')

    gem.add_dependency "nokogiri"
    gem.add_dependency "levenshtein"

  end
  Jeweler::GemcutterTasks.new

  require 'rake/testtask'
  Rake::TestTask.new(:test) do |test|
    test.libs << 'lib' << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end

  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
    test.rcov_opts << '--exclude "gems/*"'
  end

  task :default => :test



rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

