# rakefile for the PNM library.
#
# Copyright (C) 2013 Marcus Stollsteimer

require 'rake/testtask'

require './lib/pnm'

LIBNAME  = PNM::LIBNAME
HOMEPAGE = PNM::HOMEPAGE
TAGLINE  = PNM::TAGLINE


def gemspec_file
  'pnm.gemspec'
end


task :default => [:test]

Rake::TestTask.new do |t|
  t.pattern = 'test/**/test_*.rb'
  t.ruby_opts << '-rubygems'
  t.verbose = true
  t.warning = true
end


desc 'Build gem'
task :build do
  sh "gem build #{gemspec_file}"
end
