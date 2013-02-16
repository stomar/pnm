# test_image.rb: Unit tests for the PNM library.
#
# Copyright (C) 2013 Marcus Stollsteimer

require 'minitest/spec'
require 'minitest/autorun'
require 'pnm'


describe PNM::Image do

  before do
    @srcpath = File.dirname(__FILE__)
    @bilevel_path = File.expand_path("#{@srcpath}/temp.pbm")
    @bilevel_2_path = File.expand_path("#{@srcpath}/temp.pbm")
    @grayscale_path = File.expand_path("#{@srcpath}/temp.pgm")
    @color_path = File.expand_path("#{@srcpath}/temp.ppm")

    pixels = [[0,0,0,0,0],
              [0,1,1,1,0],
              [0,0,1,0,0],
              [0,0,1,0,0],
              [0,0,1,0,0],
              [0,0,0,0,0]]
    @bilevel = PNM::Image.new(:pbm, pixels)

    pixels = [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
              [0,1,1,1,0,1,1,1,1,0,1,1,1,1,1,0],
              [0,0,1,0,0,1,0,0,1,0,1,0,1,0,1,0],
              [0,0,1,0,0,1,0,0,1,0,1,0,1,0,1,0],
              [0,0,1,0,0,1,1,1,1,0,1,0,1,0,1,0],
              [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]
    @bilevel_2 = PNM::Image.new(:pbm, pixels)

    pixels = [[  0, 50,100,150],
              [ 50,100,150,200],
              [100,150,200,250]]
    @grayscale = PNM::Image.new(:pgm, pixels, {:maxgray => 250})

    pixels = [[[0,6,0], [1,5,1], [2,4,2], [3,3,4], [4,2,6]],
              [[1,5,2], [2,4,2], [3,3,2], [4,2,2], [5,1,2]],
              [[2,4,6], [3,3,4], [4,2,2], [5,1,1], [6,0,0]]]
    @color = PNM::Image.new(:ppm, pixels, {:maxgray => 6})
  end

  it 'can create a color image from gray values' do
    image = PNM::Image.new(:ppm, [[0,3,6], [3,6,9]])
    image.info.must_match %r{^PPM 3x2 Color}
    image.pixels.must_equal [[[0,0,0], [3,3,3], [6,6,6]], [[3,3,3], [6,6,6], [9,9,9]]]
  end

  it 'can write a bilevel image to an ASCII encoded file' do
    @bilevel.write(@bilevel_path, :ascii)
    File.read(@bilevel_path).must_equal File.read("#{@srcpath}/bilevel_ascii.pbm")
    File.delete(@bilevel_path)
  end

  it 'can write a bilevel image (width 5) to a binary encoded file' do
    @bilevel.write(@bilevel_path, :binary)
    File.read(@bilevel_path).must_equal File.read("#{@srcpath}/bilevel_binary.pbm")
    File.delete(@bilevel_path)
  end

  it 'can write a bilevel image (width 16) to a binary encoded file' do
    @bilevel_2.write(@bilevel_path, :binary)
    File.read(@bilevel_path).must_equal File.read("#{@srcpath}/bilevel_2_binary.pbm")
    File.delete(@bilevel_path)
  end

  it 'can write a grayscale image to an ASCII encoded file' do
    @grayscale.write(@grayscale_path, :ascii)
    File.read(@grayscale_path).must_equal File.read("#{@srcpath}/grayscale_ascii.pgm")
    File.delete(@grayscale_path)
  end

  it 'can write a grayscale image to a binary encoded file' do
    @grayscale.write(@grayscale_path, :binary)
    File.read(@grayscale_path).must_equal File.read("#{@srcpath}/grayscale_binary.pgm")
    File.delete(@grayscale_path)
  end

  it 'can write a color image to an ASCII encoded file' do
    @color.write(@color_path, :ascii)
    File.read(@color_path).must_equal File.read("#{@srcpath}/color_ascii.ppm")
    File.delete(@color_path)
  end

  it 'can write a color image to a binary encoded file' do
    @color.write(@color_path, :binary)
    File.read(@color_path).must_equal File.read("#{@srcpath}/color_binary.ppm")
    File.delete(@color_path)
  end

  it 'can return image information' do
    @bilevel.info.must_equal 'PBM 5x6 Bilevel'
    @grayscale.info.must_equal 'PGM 4x3 Grayscale'
    @color.info.must_equal 'PPM 5x3 Color'
  end
end
