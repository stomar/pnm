# test_image.rb: Unit tests for the PNM library.
#
# Copyright (C) 2013-2014 Marcus Stollsteimer

require 'minitest/spec'
require 'minitest/autorun'
require 'pnm/image'


describe PNM::Image do

  before do
    @srcpath   = File.dirname(__FILE__)
    @temp_path = File.expand_path("#{@srcpath}/temp.pnm")

    pixels = [[0,0,0,0,0],
              [0,1,1,1,0],
              [0,0,1,0,0],
              [0,0,1,0,0],
              [0,0,1,0,0],
              [0,0,0,0,0]]
    comment = 'Bilevel'
    @bilevel = PNM::Image.new(pixels, {:comment => comment})

    pixels = [[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
              [0,1,1,1,0,1,1,1,1,0,1,1,1,1,1,0],
              [0,0,1,0,0,1,0,0,1,0,1,0,1,0,1,0],
              [0,0,1,0,0,1,0,0,1,0,1,0,1,0,1,0],
              [0,0,1,0,0,1,1,1,1,0,1,0,1,0,1,0],
              [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]
    @bilevel_2 = PNM::Image.new(pixels)

    pixels = [[  0, 50,100,150],
              [ 50,100,150,200],
              [100,150,200,250]]
    comment = "Grayscale\n(with multiline comment)"
    @grayscale = PNM::Image.new(pixels, {:maxgray => 250, :comment => comment})

    pixels = [[65,66], [13,10], [65,66]]
    @grayscale_crlf = PNM::Image.new(pixels)

    pixels = [[[0,6,0], [1,5,1], [2,4,2], [3,3,4], [4,2,6]],
              [[1,5,2], [2,4,2], [3,3,2], [4,2,2], [5,1,2]],
              [[2,4,6], [3,3,4], [4,2,2], [5,1,1], [6,0,0]]]
    @color = PNM::Image.new(pixels, {:maxgray => 6})
  end

  it 'sets maxgray to 1 for bilevel images' do
    image = PNM::Image.new([[0,1,0], [1,0,1]])
    image.type.must_equal :pbm
    image.maxgray.must_equal 1
  end

  it 'sets maxgray by default to 255 for grayscale images' do
    image = PNM::Image.new([[0,10,20], [10,20,30]])
    image.type.must_equal :pgm
    image.maxgray.must_equal 255
  end

  it 'sets maxgray by default to 255 for color images' do
    image = PNM::Image.new([[[0,0,0], [10,10,10]], [[10,10,10], [20,20,20]]])
    image.type.must_equal :ppm
    image.maxgray.must_equal 255
  end

  it 'ignores maxgray for bilevel images and sets it to 1' do
    image = PNM::Image.new([[0,1,0], [1,0,1]], {:type => :pbm, :maxgray => 255})
    image.type.must_equal :pbm
    image.maxgray.must_equal 1
  end

  it 'can create a grayscale image from bilevel values (using type)' do
    image = PNM::Image.new([[0,1,0], [1,0,1]], {:type => :pgm})
    image.type.must_equal :pgm
    image.pixels.must_equal [[0,1,0], [1,0,1]]
    image.maxgray.must_equal 255
  end

  it 'can create a grayscale image from bilevel values (using maxgray)' do
    image = PNM::Image.new([[0,1,0], [1,0,1]], {:maxgray => 1})
    image.type.must_equal :pgm
    image.pixels.must_equal [[0,1,0], [1,0,1]]
    image.maxgray.must_equal 1
  end

  it 'can create a color image from bilevel values' do
    image = PNM::Image.new([[0,1,0], [1,0,1]], {:type => :ppm})
    image.info.must_match %r{^PPM 3x2 Color}
    image.pixels.must_equal [[[0,0,0], [1,1,1], [0,0,0]], [[1,1,1], [0,0,0], [1,1,1]]]
    image.maxgray.must_equal 255
  end

  it 'can create a color image from bilevel values with a given maxgray' do
    image = PNM::Image.new([[0,1,0], [1,0,1]], {:type => :ppm, :maxgray => 2})
    image.info.must_match %r{^PPM 3x2 Color}
    image.pixels.must_equal [[[0,0,0], [1,1,1], [0,0,0]], [[1,1,1], [0,0,0], [1,1,1]]]
    image.maxgray.must_equal 2
  end

  it 'can create a color image from gray values' do
    image = PNM::Image.new([[0,3,6], [3,6,9]], {:type => :ppm})
    image.info.must_match %r{^PPM 3x2 Color}
    image.pixels.must_equal [[[0,0,0], [3,3,3], [6,6,6]], [[3,3,3], [6,6,6], [9,9,9]]]
  end

  it 'does not modify the input data for color images created from gray values' do
    data = [[0,3,6], [3,6,9]]
    PNM::Image.new(data, {:type => :ppm})
    data.must_equal [[0,3,6], [3,6,9]]
  end

  it 'can write a bilevel image to an ASCII encoded file' do
    @bilevel.write(@temp_path, :ascii)
    File.binread(@temp_path).must_equal File.binread("#{@srcpath}/bilevel_ascii.pbm")
    File.delete(@temp_path)
  end

  it 'can write a bilevel image (width 5) to a binary encoded file' do
    @bilevel.write(@temp_path, :binary)
    File.binread(@temp_path).must_equal File.binread("#{@srcpath}/bilevel_binary.pbm")
    File.delete(@temp_path)
  end

  it 'can write a bilevel image (width 16) to a binary encoded file' do
    @bilevel_2.write(@temp_path, :binary)
    File.binread(@temp_path).must_equal File.binread("#{@srcpath}/bilevel_2_binary.pbm")
    File.delete(@temp_path)
  end

  it 'can write a grayscale image to an ASCII encoded file' do
    @grayscale.write(@temp_path, :ascii)
    File.binread(@temp_path).must_equal File.binread("#{@srcpath}/grayscale_ascii.pgm")
    File.delete(@temp_path)
  end

  it 'can write a grayscale image to a binary encoded file' do
    @grayscale.write(@temp_path, :binary)
    File.binread(@temp_path).must_equal File.binread("#{@srcpath}/grayscale_binary.pgm")
    File.delete(@temp_path)
  end

  it 'can write a color image to an ASCII encoded file' do
    @color.write(@temp_path, :ascii)
    File.binread(@temp_path).must_equal File.binread("#{@srcpath}/color_ascii.ppm")
    File.delete(@temp_path)
  end

  it 'can write a color image to a binary encoded file' do
    @color.write(@temp_path, :binary)
    File.binread(@temp_path).must_equal File.binread("#{@srcpath}/color_binary.ppm")
    File.delete(@temp_path)
  end

  it 'can return image information' do
    @bilevel.info.must_equal 'PBM 5x6 Bilevel'
    @grayscale.info.must_equal 'PGM 4x3 Grayscale'
    @color.info.must_equal 'PPM 5x3 Color'
  end

  it 'can write binary data containing CRLF' do
    @grayscale_crlf.write(@temp_path, :binary)
    File.binread(@temp_path).must_equal File.binread("#{@srcpath}/grayscale_binary_crlf.pgm")
    File.delete(@temp_path)
  end

  it 'can write binary data containing CRLF to an I/O stream' do
    File.open(@temp_path, 'w') {|f| @grayscale_crlf.write(f, :binary) }
    File.binread(@temp_path).must_equal File.binread("#{@srcpath}/grayscale_binary_crlf.pgm")
    File.delete(@temp_path)
  end
end
