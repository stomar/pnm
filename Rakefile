# frozen_string_literal: true

require "rake/testtask"

require_relative "lib/pnm"


def gemspec_file
  "pnm.gemspec"
end


task default: :test

Rake::TestTask.new do |t|
  t.pattern = "test/**/test_*.rb"
  t.verbose = true
  t.warning = true
end


desc "Run benchmarks"
task :benchmark do
  Dir["benchmark/**/bm_*.rb"].each {|f| require_relative f }
end


desc "Build gem"
task :build do
  sh "gem build #{gemspec_file}"
end
