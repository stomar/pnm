# test_exceptions.rb: Unit tests for the PNM library.
#
# Copyright (C) 2013-2017 Marcus Stollsteimer

require 'minitest/autorun'
require 'stringio'
require 'pnm'


describe 'PNM.create' do

  it 'raises an exception for invalid data type (String)' do
    data = '0'
    lambda { PNM.create(data) }.must_raise PNM::ArgumentError
  end

  it 'raises an exception for invalid type' do
    data = [[0, 0], [0, 0]]
    lambda { PNM.create(data, :type => :abc) }.must_raise PNM::ArgumentError
  end

  it 'raises an exception for invalid maxgray (String)' do
    data = [[0, 0], [0, 0]]
    lambda { PNM.create(data, :maxgray => '255') }.must_raise PNM::ArgumentError
  end

  it 'raises an exception for invalid maxgray (> 255)' do
    data = [[0, 0], [0, 0]]
    lambda { PNM.create(data, :maxgray => 256) }.must_raise PNM::ArgumentError
  end

  it 'raises an exception for invalid maxgray (0)' do
    data = [[0, 0], [0, 0]]
    lambda { PNM.create(data, :maxgray => 0) }.must_raise PNM::ArgumentError
  end

  it 'raises an exception for invalid comment (Integer)' do
    data = [[0, 0], [0, 0]]
    lambda { PNM.create(data, :comment => 1) }.must_raise PNM::ArgumentError
  end

  it 'raises an exception for image type and data mismatch (PBM)' do
    data = [[[0,0,0], [0,0,0]], [[0,0,0], [0,0,0]]]
    lambda { PNM.create(data, :type => :pbm) }.must_raise PNM::DataError
  end

  it 'raises an exception for image type and data mismatch (PGM)' do
    data = [[[0,0,0], [0,0,0]], [[0,0,0], [0,0,0]]]
    lambda { PNM.create(data, :type => :pgm) }.must_raise PNM::DataError
  end

  it 'raises an exception for non-integer pixel value (String)' do
    data = [[0, 0], ['X', 0]]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for non-integer pixel value (Float)' do
    data = [[0, 0], [0.5, 0]]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for rows of different size' do
    data = [[0, 0], [0, 0, 0]]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid array dimensions (#1)' do
    data = [0, 0, 0]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid array dimensions (#2)' do
    data = [[0, 0], 0, 0]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid array dimensions (#3)' do
    data = [[0, 0], [0, [0, 0]]]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid array dimensions (#4)' do
    data = [[[0,0], [0,0]], [[0,0], [0,0]]]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid array dimensions (#5)' do
    data = [[[0,0,0], [0,0,0]], [0 ,0]]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid array dimensions (#6)' do
    data = [[[0,0,0], 0], [0 ,0]]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for an empty array' do
    data = [[]]
    lambda { PNM.create(data) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid PBM data (> 1)' do
    data = [[0, 0], [2, 0]]
    lambda { PNM.create(data, :type => :pbm) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid PBM data (< 0)' do
    data = [[0, 0], [-1, 0]]
    lambda { PNM.create(data, :type => :pbm) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid PGM data (> 255)' do
    data = [[0, 0], [1, 500]]
    lambda { PNM.create(data, :type => :pgm) }.must_raise PNM::DataError
  end

  it 'raises an exception for invalid PGM data (> maxgray)' do
    data = [[0, 0], [1, 200]]
    lambda { PNM.create(data, :maxgray => 100) }.must_raise PNM::DataError
  end
end


describe 'PNM.read' do

  it 'raises an exception for integer argument' do
    lambda { PNM.read(123) }.must_raise PNM::ArgumentError
  end

  it 'raises an exception for unknown magic number' do
    file = StringIO.new('P0 1 1 0')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for an empty file' do
    file = StringIO.new('')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for missing tokens (#1)' do
    file = StringIO.new('P1')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for missing tokens (#2)' do
    file = StringIO.new('P1 1')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for missing tokens (#3)' do
    file = StringIO.new('P1 1 ')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for missing tokens (#4)' do
    file = StringIO.new('P1 1 1')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for missing tokens (#5)' do
    file = StringIO.new("P1 1  # Test\n 1")
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for missing tokens (#6)' do
    file = StringIO.new("P2 1 1 255")
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for token of wrong type (#1)' do
    file = StringIO.new('P1 ? 1 0')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for token of wrong type (#2)' do
    file = StringIO.new('P1 1 X 0')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for token of wrong type (#3)' do
    file = StringIO.new('P2 1 1 foo 0')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for zero width' do
    file = StringIO.new('P2 0 1 255 0')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for zero height' do
    file = StringIO.new('P2 1 0 255 0')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for invalid maxgray (> 255)' do
    file = StringIO.new('P2 1 1 256 0')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for invalid maxgray (0)' do
    file = StringIO.new('P2 1 1 0 0')
    lambda { PNM.read(file) }.must_raise PNM::ParserError
  end

  it 'raises an exception for image dimension mismatch (#1)' do
    file = StringIO.new('P1 2 3 0 0 0 0 0')
    lambda { PNM.read(file) }.must_raise PNM::DataSizeError
  end

  it 'raises an exception for image dimension mismatch (#2)' do
    file = StringIO.new('P1 2 3 0 0 0 0 0 0 0')
    lambda { PNM.read(file) }.must_raise PNM::DataSizeError
  end

  it 'raises an exception for image dimension mismatch (#3)' do
    file = StringIO.new('P3 2 3 255 0 0 0 0 0 0')
    lambda { PNM.read(file) }.must_raise PNM::DataSizeError
  end

  it 'raises an exception for image dimension mismatch (#4)' do
    file = StringIO.new('P5 2 3 255 AAAAAAA')
    lambda { PNM.read(file) }.must_raise PNM::DataSizeError
  end

  it 'raises an exception for image dimension mismatch (#5)' do
    file = StringIO.new('P5 2 3 255 AAAAAAA')
    lambda { PNM.read(file) }.must_raise PNM::DataSizeError
  end

  it 'raises an exception for non-numeric image data' do
    file = StringIO.new('P1 2 3 0 X 0 0 0 0')
    lambda { PNM.read(file) }.must_raise PNM::DataError
  end
end
