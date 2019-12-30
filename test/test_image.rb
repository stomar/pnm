# frozen_string_literal: true

# test_image.rb: Unit tests for the PNM library.
#
# Copyright (C) 2013-2019 Marcus Stollsteimer

require "minitest/autorun"
require "pnm"

require_relative "backports"


describe PNM::Image do

  before do
    @srcpath   = File.dirname(__FILE__)
    @temp_path = File.expand_path("#{@srcpath}/temp.pnm")

    pixels = [[0, 0, 0, 0, 0],
              [0, 1, 1, 1, 0],
              [0, 0, 1, 0, 0],
              [0, 0, 1, 0, 0],
              [0, 0, 1, 0, 0],
              [0, 0, 0, 0, 0]]
    comment = "Bilevel"
    @bilevel = PNM.create(pixels, comment: comment)

    pixels = [[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
              [0, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0],
              [0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0],
              [0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0],
              [0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0],
              [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]]
    @bilevel2 = PNM.create(pixels)

    pixels = [[  0,  50, 100, 150],
              [ 50, 100, 150, 200],
              [100, 150, 200, 250]]
    comment = "Grayscale\n(with multiline comment)"
    @grayscale = PNM.create(pixels, maxgray: 250, comment: comment)

    pixels = [[65, 66], [13, 10], [65, 66]]
    @grayscale_crlf = PNM.create(pixels)

    pixels = [[[0, 6, 0], [1, 5, 1], [2, 4, 2], [3, 3, 4], [4, 2, 6]],
              [[1, 5, 2], [2, 4, 2], [3, 3, 2], [4, 2, 2], [5, 1, 2]],
              [[2, 4, 6], [3, 3, 4], [4, 2, 2], [5, 1, 1], [6, 0, 0]]]
    @color = PNM.create(pixels, maxgray: 6)
  end

  it "freezes pixel data" do
    _ { @bilevel.pixels << [1, 1, 0, 1, 1] }.must_raise RuntimeError
  end

  it "freezes comment string" do
    _ { @bilevel.comment << "string" }.must_raise RuntimeError
  end

  it "sets maxgray to 1 for bilevel images" do
    image = PNM.create([[0, 1, 0], [1, 0, 1]])
    _(image.type).must_equal :pbm
    _(image.maxgray).must_equal 1
  end

  it "sets maxgray by default to 255 for grayscale images" do
    image = PNM.create([[0, 10, 20], [10, 20, 30]])
    _(image.type).must_equal :pgm
    _(image.maxgray).must_equal 255
  end

  it "sets maxgray by default to 255 for color images" do
    image = PNM.create([[[0, 0, 0], [10, 10, 10]], [[10, 10, 10], [20, 20, 20]]])
    _(image.type).must_equal :ppm
    _(image.maxgray).must_equal 255
  end

  it "accepts setting of maxgray to 1 for bilevel images" do
    image = PNM.create([[0, 1, 0], [1, 0, 1]], maxgray: 1)
    _(image.type).must_equal :pbm
    _(image.maxgray).must_equal 1
  end

  it "ignores invalid maxgray for bilevel images and sets it to 1" do
    image = PNM.create([[0, 1, 0], [1, 0, 1]], type: :pbm, maxgray: 255)
    _(image.type).must_equal :pbm
    _(image.maxgray).must_equal 1
  end

  it "can create a grayscale image from bilevel values (using type)" do
    image = PNM.create([[0, 1, 0], [1, 0, 1]], type: :pgm)
    _(image.type).must_equal :pgm
    _(image.pixels).must_equal [[0, 1, 0], [1, 0, 1]]
    _(image.maxgray).must_equal 255
  end

  it "also accepts types given as string instead of symbol" do
    image = PNM.create([[0, 1, 0], [1, 0, 1]], type: "pgm")
    _(image.type).must_equal :pgm
  end

  it "can create a grayscale image from bilevel values (using maxgray)" do
    image = PNM.create([[0, 1, 0], [1, 0, 1]], maxgray: 2)
    _(image.type).must_equal :pgm
    _(image.pixels).must_equal [[0, 1, 0], [1, 0, 1]]
    _(image.maxgray).must_equal 2
  end

  it "can create a color image from bilevel values" do
    image = PNM.create([[0, 1, 0], [1, 0, 1]], type: :ppm)
    _(image.info).must_equal "PPM 3x2 Color"
    _(image.pixels).must_equal [[[0, 0, 0], [1, 1, 1], [0, 0, 0]], [[1, 1, 1], [0, 0, 0], [1, 1, 1]]]
    _(image.maxgray).must_equal 255
  end

  it "can create a color image from bilevel values with a given maxgray" do
    image = PNM.create([[0, 1, 0], [1, 0, 1]], type: :ppm, maxgray: 2)
    _(image.info).must_equal "PPM 3x2 Color"
    _(image.pixels).must_equal [[[0, 0, 0], [1, 1, 1], [0, 0, 0]], [[1, 1, 1], [0, 0, 0], [1, 1, 1]]]
    _(image.maxgray).must_equal 2
  end

  it "can create a color image from gray values" do
    image = PNM.create([[0, 3, 6], [3, 6, 9]], type: :ppm)
    _(image.info).must_equal "PPM 3x2 Color"
    _(image.pixels).must_equal [[[0, 0, 0], [3, 3, 3], [6, 6, 6]], [[3, 3, 3], [6, 6, 6], [9, 9, 9]]]
  end

  it "does not modify the input data for color images created from gray values" do
    data = [[0, 3, 6], [3, 6, 9]]
    PNM.create(data, type: :ppm)
    _(data).must_equal [[0, 3, 6], [3, 6, 9]]
  end

  it "can write a bilevel image to an ASCII encoded file" do
    @bilevel.write(@temp_path, :ascii)
    _(File.binread(@temp_path)).must_equal File.binread("#{@srcpath}/bilevel_ascii.pbm")
    File.delete(@temp_path)
  end

  it "can write a bilevel image (width 5) to a binary encoded file" do
    @bilevel.write(@temp_path, :binary)
    _(File.binread(@temp_path)).must_equal File.binread("#{@srcpath}/bilevel_binary.pbm")
    File.delete(@temp_path)
  end

  it "can write a bilevel image (width 16) to a binary encoded file" do
    @bilevel2.write(@temp_path, :binary)
    _(File.binread(@temp_path)).must_equal File.binread("#{@srcpath}/bilevel_2_binary.pbm")
    File.delete(@temp_path)
  end

  it "can write a grayscale image to an ASCII encoded file" do
    @grayscale.write(@temp_path, :ascii)
    _(File.binread(@temp_path)).must_equal File.binread("#{@srcpath}/grayscale_ascii.pgm")
    File.delete(@temp_path)
  end

  it "can write a grayscale image to a binary encoded file" do
    @grayscale.write(@temp_path, :binary)
    _(File.binread(@temp_path)).must_equal File.binread("#{@srcpath}/grayscale_binary.pgm")
    File.delete(@temp_path)
  end

  it "can write a color image to an ASCII encoded file" do
    @color.write(@temp_path, :ascii)
    _(File.binread(@temp_path)).must_equal File.binread("#{@srcpath}/color_ascii.ppm")
    File.delete(@temp_path)
  end

  it "can write a color image to a binary encoded file" do
    @color.write(@temp_path, :binary)
    _(File.binread(@temp_path)).must_equal File.binread("#{@srcpath}/color_binary.ppm")
    File.delete(@temp_path)
  end

  it "can write a bilevel image to a file, adding the extension" do
    @bilevel.write_with_extension(@temp_path)
    _(File.binread("#{@temp_path}.pbm")).must_equal File.binread("#{@srcpath}/bilevel_binary.pbm")
    File.delete("#{@temp_path}.pbm")
  end

  it "can write a grayscale image to a file, adding the extension" do
    @grayscale.write_with_extension(@temp_path, :ascii)
    _(File.binread("#{@temp_path}.pgm")).must_equal File.binread("#{@srcpath}/grayscale_ascii.pgm")
    File.delete("#{@temp_path}.pgm")
  end

  it "can write a color image to a file, adding the extension" do
    @color.write_with_extension(@temp_path, :binary)
    _(File.binread("#{@temp_path}.ppm")).must_equal File.binread("#{@srcpath}/color_binary.ppm")
    File.delete("#{@temp_path}.ppm")
  end

  it "can return image information" do
    _(@bilevel.info).must_equal "PBM 5x6 Bilevel"
    _(@grayscale.info).must_equal "PGM 4x3 Grayscale"
    _(@color.info).must_equal "PPM 5x3 Color"
  end

  it "can return meaningful debugging information" do
    _(@bilevel.inspect).must_match   %r{\A#<PNM::\w+Image:0x\h+ PBM 5x6 Bilevel>\z}
    _(@grayscale.inspect).must_match %r{\A#<PNM::\w+Image:0x\h+ PGM 4x3 Grayscale, maxgray=250>\z}
    _(@color.inspect).must_match     %r{\A#<PNM::\w+Image:0x\h+ PPM 5x3 Color, maxgray=6>\z}
  end

  it "can write binary data containing CRLF" do
    @grayscale_crlf.write(@temp_path, :binary)
    _(File.binread(@temp_path)).must_equal File.binread("#{@srcpath}/grayscale_binary_crlf.pgm")
    File.delete(@temp_path)
  end

  it "can write binary data containing CRLF to an I/O stream" do
    File.open(@temp_path, "w") {|f| @grayscale_crlf.write(f, :binary) }
    _(File.binread(@temp_path)).must_equal File.binread("#{@srcpath}/grayscale_binary_crlf.pgm")
    File.delete(@temp_path)
  end

  it "can write zero-length comments" do
    comment = ""
    PNM.create([[0, 0]], comment: comment).write(@temp_path, :ascii)
    _(File.binread(@temp_path)).must_equal "P1\n#\n2 1\n0 0\n"
    File.delete(@temp_path)
  end

  it "can write comments with trailing zero-length line" do
    comment = "An empty line:\n"
    PNM.create([[0, 0]], comment: comment).write(@temp_path, :ascii)
    _(File.binread(@temp_path)).must_equal "P1\n# An empty line:\n#\n2 1\n0 0\n"
    File.delete(@temp_path)
  end

  it "can check equality of images (1)" do
    pixels = [[0, 1, 0], [1, 0, 1]]
    bilevel  = PNM.create(pixels, comment: "image")
    bilevel2 = PNM.create(pixels, comment: "image")

    _(bilevel2 == bilevel).must_equal true
  end

  it "can check equality of images (2)" do
    pixels = [[0, 1, 0], [1, 0, 1]]
    bilevel  = PNM.create(pixels, comment: "image")
    bilevel2 = PNM.create(pixels, comment: "other image")

    _(bilevel2 == bilevel).must_equal false
  end

  it "can check equality of images (3)" do
    pixels = [[0, 1, 0], [1, 0, 1]]
    bilevel  = PNM.create(pixels)
    bilevel2 = PNM.create(pixels.reverse)

    _(bilevel2 == bilevel).must_equal false
  end

  it "can check equality of images (4)" do
    pixels = [[0, 1, 0], [1, 0, 1]]
    bilevel   = PNM.create(pixels, type: :pbm)
    graylevel = PNM.create(pixels, type: :pgm)

    _(graylevel == bilevel).must_equal false
  end

  it "can check equality of images (5)" do
    pixels = [[0, 1, 2], [3, 4, 5]]
    graylevel  = PNM.create(pixels, maxgray: 10)
    graylevel2 = PNM.create(pixels, maxgray: 255)

    _(graylevel2 == graylevel).must_equal false
  end

  it "can check equality of images (6)" do
    image = PNM.create([[0, 1, 2], [3, 4, 5]])

    _(image == "a string").must_equal false
  end
end
