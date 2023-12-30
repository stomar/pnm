# frozen_string_literal: true

require "minitest/autorun"
require "pnm"


describe PNM do

  before do
    @srcpath = File.dirname(__FILE__)
  end

  it "can read an ASCII encoded PBM file" do
    file = File.expand_path("#{@srcpath}/bilevel_ascii.pbm")
    image = PNM.read(file)

    _(image.info).must_equal "PBM 5x6 Bilevel"
    _(image.maxgray).must_equal 1
    _(image.comment).must_equal "Bilevel"
    _(image.pixels).must_equal [[0, 0, 0, 0, 0],
                                [0, 1, 1, 1, 0],
                                [0, 0, 1, 0, 0],
                                [0, 0, 1, 0, 0],
                                [0, 0, 1, 0, 0],
                                [0, 0, 0, 0, 0]]
  end

  it "can read an ASCII encoded PGM file" do
    file = File.expand_path("#{@srcpath}/grayscale_ascii.pgm")
    image = PNM.read(file)

    _(image.info).must_equal "PGM 4x3 Grayscale"
    _(image.maxgray).must_equal 250
    _(image.comment).must_equal "Grayscale\n(with multiline comment)"
    _(image.pixels).must_equal [[  0,  50, 100, 150],
                                [ 50, 100, 150, 200],
                                [100, 150, 200, 250]]
  end

  it "can read an ASCII encoded PPM file" do
    file = File.expand_path("#{@srcpath}/color_ascii.ppm")
    image = PNM.read(file)

    _(image.info).must_equal "PPM 5x3 Color"
    _(image.maxgray).must_equal 6
    _(image.pixels).must_equal [[[0, 6, 0], [1, 5, 1], [2, 4, 2], [3, 3, 4], [4, 2, 6]],
                                [[1, 5, 2], [2, 4, 2], [3, 3, 2], [4, 2, 2], [5, 1, 2]],
                                [[2, 4, 6], [3, 3, 4], [4, 2, 2], [5, 1, 1], [6, 0, 0]]]
  end

  it "can read a binary encoded PBM file" do
    file = File.expand_path("#{@srcpath}/bilevel_binary.pbm")
    image = PNM.read(file)

    _(image.info).must_equal "PBM 5x6 Bilevel"
    _(image.maxgray).must_equal 1
    _(image.comment).must_equal "Bilevel"
    _(image.pixels).must_equal [[0, 0, 0, 0, 0],
                                [0, 1, 1, 1, 0],
                                [0, 0, 1, 0, 0],
                                [0, 0, 1, 0, 0],
                                [0, 0, 1, 0, 0],
                                [0, 0, 0, 0, 0]]
  end

  it "can read a binary encoded PGM file" do
    file = File.expand_path("#{@srcpath}/grayscale_binary.pgm")
    image = PNM.read(file)

    _(image.info).must_equal "PGM 4x3 Grayscale"
    _(image.maxgray).must_equal 250
    _(image.comment).must_equal "Grayscale\n(with multiline comment)"
    _(image.pixels).must_equal [[  0,  50, 100, 150],
                                [ 50, 100, 150, 200],
                                [100, 150, 200, 250]]
  end

  it "can read a binary encoded PPM file" do
    file = File.expand_path("#{@srcpath}/color_binary.ppm")
    image = PNM.read(file)

    _(image.info).must_equal "PPM 5x3 Color"
    _(image.maxgray).must_equal 6
    _(image.pixels).must_equal [[[0, 6, 0], [1, 5, 1], [2, 4, 2], [3, 3, 4], [4, 2, 6]],
                                [[1, 5, 2], [2, 4, 2], [3, 3, 2], [4, 2, 2], [5, 1, 2]],
                                [[2, 4, 6], [3, 3, 4], [4, 2, 2], [5, 1, 1], [6, 0, 0]]]
  end

  it "can read binary data containing CRLF" do
    file = File.expand_path("#{@srcpath}/grayscale_binary_crlf.pgm")

    image = PNM.read(file)
    _(image.pixels).must_equal [[65, 66], [13, 10], [65, 66]]
  end

  it "can read binary data containing CRLF from an I/O stream" do
    file = File.expand_path("#{@srcpath}/grayscale_binary_crlf.pgm")

    image = File.open(file, "r") {|f| PNM.read(f) }
    _(image.pixels).must_equal [[65, 66], [13, 10], [65, 66]]
  end
end
