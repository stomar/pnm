# frozen_string_literal: true

require "./lib/pnm"

version  = PNM::VERSION
date     = PNM::DATE
homepage = PNM::HOMEPAGE
tagline  = PNM::TAGLINE

Gem::Specification.new do |s|
  s.name              = "pnm"
  s.version           = version
  s.date              = date

  s.description = "PNM is a pure Ruby library for creating, reading, " \
                  "and writing of PNM image files (Portable Anymap): " \
                  "PBM (Portable Bitmap), " \
                  "PGM (Portable Graymap), and " \
                  "PPM (Portable Pixmap)."
  s.summary = "PNM - #{tagline}"

  s.authors = ["Marcus Stollsteimer"]
  s.email = "sto.mar@web.de"
  s.homepage = homepage

  s.license = "GPL-3.0"

  s.required_ruby_version = ">= 1.9.3"

  s.add_development_dependency "minitest", ">= 5.0"
  s.add_development_dependency "rake", ">= 10.0"

  s.require_paths = ["lib"]

  s.test_files = Dir.glob("test/**/test_*.rb")

  s.files =
    %w[
      README.md
      Rakefile
      pnm.gemspec
      .yardopts
    ] +
    Dir.glob("{benchmark,lib,test}/**/*")

  s.extra_rdoc_files = ["README.md"]
  s.rdoc_options = ["--charset=UTF-8", "--main=README.md"]
end
