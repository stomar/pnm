# test_converter.rb: Unit tests for the PNM library.
#
# Copyright (C) 2013 Marcus Stollsteimer

require 'minitest/spec'
require 'minitest/autorun'
require 'pnm/converter'


describe PNM::Converter do

  before do
    @converter = PNM::Converter

    @pbm6  = {
               :width  => 6,
               :height => 2,
               :array  => [[0,1,0,0,1,1], [0,0,0,1,1,1]],
               :ascii  => "0 1 0 0 1 1\n0 0 0 1 1 1\n",
               :binary => ['4C1C'].pack('H*')
             }

    @pbm14 = {
               :width  => 14,
               :height => 2,
               :array  => [[0,0,1,1,1,0,0,0,1,1,0,0,1,0], [0,1,0,1,1,0,1,1,1,0,1,1,1,1]],
               :ascii  => "0 0 1 1 1 0 0 0 1 1 0 0 1 0\n0 1 0 1 1 0 1 1 1 0 1 1 1 1\n",
               :binary => ['38C85BBC'].pack('H*')
             }

    @pbm = @pbm14

    @pgm =   {
               :width  => 4,
               :height => 3,
               :array  => [[0, 85, 170, 255], [85, 170, 255, 0], [170, 255, 0, 85]],
               :ascii  => "0 85 170 255\n85 170 255 0\n170 255 0 85\n",
               :binary => ['0055AAFF55AAFF00AAFF0055'].pack('H*')
             }

    @ppm =   {
               :width  => 3,
               :height => 2,
               :array  => [[[0,128,255], [128,255,0], [255,0,128]],
                           [[255,128,0], [128,0,255], [0,255,128]]],
               :ascii  => "0 128 255 128 255 0 255 0 128\n255 128 0 128 0 255 0 255 128\n",
               :binary => ['0080FF80FF00FF0080FF80008000FF00FF80'].pack('H*')
             }
  end

  it 'can convert from ASCII encoded PBM data' do
    width    = @pbm[:width]
    height   = @pbm[:height]
    data     = @pbm[:ascii]
    expected = @pbm[:array]

    @converter.ascii2array(:pbm, width, height, data).must_equal expected
  end

  it 'can convert from ASCII encoded PGM data' do
    width    = @pgm[:width]
    height   = @pgm[:height]
    data     = @pgm[:ascii]
    expected = @pgm[:array]

    @converter.ascii2array(:pgm, width, height, data).must_equal expected
  end

  it 'can convert from ASCII encoded PPM data' do
    width    = @ppm[:width]
    height   = @ppm[:height]
    data     = @ppm[:ascii]
    expected = @ppm[:array]

    @converter.ascii2array(:ppm, width, height, data).must_equal expected
  end

  it 'accepts ASCII encoded PGM data with arbitrary whitespace' do
    width    = 4
    height   = 3
    data     = "  \n 10 90\t170\r250\n90 \t170   250 \t\r\n\t 10\n\n\n170\n250\n10\n90\n"
    expected = [[10, 90, 170, 250], [90, 170, 250, 10], [170, 250, 10, 90]]

    @converter.ascii2array(:pgm, width, height, data).must_equal expected
  end

  it 'can convert from binary encoded PBM data (width 6)' do
    width    = @pbm6[:width]
    height   = @pbm6[:height]
    data     = @pbm6[:binary]
    expected = @pbm6[:array]

    @converter.binary2array(:pbm, width, height, data).must_equal expected
  end

  it 'can convert from binary encoded PBM data (width 14)' do
    width    = @pbm14[:width]
    height   = @pbm14[:height]
    data     = @pbm14[:binary]
    expected = @pbm14[:array]

    @converter.binary2array(:pbm, width, height, data).must_equal expected
  end

  it 'can convert from binary encoded PGM data' do
    width    = @pgm[:width]
    height   = @pgm[:height]
    data     = @pgm[:binary]
    expected = @pgm[:array]

    @converter.binary2array(:pgm, width, height, data).must_equal expected
  end

  it 'can convert from binary encoded PPM data' do
    width    = @ppm[:width]
    height   = @ppm[:height]
    data     = @ppm[:binary]
    expected = @ppm[:array]

    @converter.binary2array(:ppm, width, height, data).must_equal expected
  end

  it 'accepts an additional whitespace character for binary encoded data' do
    width    = @pbm14[:width]
    height   = @pbm14[:height]
    data     = @pbm14[:binary] + "\t"
    expected = @pbm14[:array]

    @converter.binary2array(:pbm, width, height, data).must_equal expected
  end

  it 'can convert to ASCII encoded PBM data' do
    data     = @pbm[:array]
    expected = @pbm[:ascii]

    @converter.array2ascii(data).must_equal expected
  end

  it 'can convert to ASCII encoded PGM data' do
    data     = @pgm[:array]
    expected = @pgm[:ascii]

    @converter.array2ascii(data).must_equal expected
  end

  it 'can convert to ASCII encoded PPM data' do
    data     = @ppm[:array]
    expected = @ppm[:ascii]

    @converter.array2ascii(data).must_equal expected
  end

  it 'can convert to binary encoded PBM data (width 6)' do
    data     = @pbm6[:array]
    expected = @pbm6[:binary]

    @converter.array2binary(:pbm, data).must_equal expected
  end

  it 'can convert to binary encoded PBM data (width 14)' do
    data     = @pbm14[:array]
    expected = @pbm14[:binary]

    @converter.array2binary(:pbm, data).must_equal expected
  end

  it 'can convert to binary encoded PGM data' do
    data     = @pgm[:array]
    expected = @pgm[:binary]

    @converter.array2binary(:pgm, data).must_equal expected
  end

  it 'can convert to binary encoded PPM data' do
    data     = @ppm[:array]
    expected = @ppm[:binary]

    @converter.array2binary(:ppm, data).must_equal expected
  end

  it 'can calculate correct byte widths for a PBM image' do
    @converter.byte_width(:pbm,  0).must_equal 0
    @converter.byte_width(:pbm,  1).must_equal 1
    @converter.byte_width(:pbm,  7).must_equal 1
    @converter.byte_width(:pbm,  8).must_equal 1
    @converter.byte_width(:pbm,  9).must_equal 2
    @converter.byte_width(:pbm, 64).must_equal 8
    @converter.byte_width(:pbm, 65).must_equal 9
  end

  it 'can calculate correct byte widths for a PGM image' do
    @converter.byte_width(:pgm, 13).must_equal 13
  end

  it 'can calculate correct byte widths for a PPM image' do
    @converter.byte_width(:ppm, 13).must_equal 39
  end
end
