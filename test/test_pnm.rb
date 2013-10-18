# test_pnm.rb: Unit tests for the PNM library.
#
# Copyright (C) 2013 Marcus Stollsteimer

require 'minitest/spec'
require 'minitest/autorun'
require 'pnm'


describe PNM do

  before do
    @srcpath = File.dirname(__FILE__)
  end

  it 'can read an ASCII encoded PGM file' do
    file = File.expand_path("#{@srcpath}/grayscale_ascii.pgm")
    image = PNM.read(file)

    image.info.must_match %r{^PGM 4x3 Grayscale}
    image.maxgray.must_equal 250
    image.pixels.must_equal [[0,50,100,150], [50,100,150,200], [100,150,200,250]]
  end
end
