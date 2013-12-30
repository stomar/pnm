# test_parser.rb: Unit tests for the PNM library.
#
# Copyright (C) 2013 Marcus Stollsteimer

require 'minitest/spec'
require 'minitest/autorun'
require 'pnm/parser'


describe PNM::Parser do

  before do
    @parser = PNM::Parser
  end

  it 'can parse ASCII encoded PBM data' do
    content =<<-EOF.chomp.gsub(/^ */, '')
      P1 6 2
      0 1 0 0 1 1
      0 0 0 1 1 1
    EOF
    expected = {
      :magic_number => 'P1',
      :width        => 6,
      :height       => 2,
      :data         => "0 1 0 0 1 1\n0 0 0 1 1 1"
    }

    @parser.parse(content).must_equal expected
  end

  it 'can parse ASCII encoded PGM data' do
    content =<<-EOF.chomp.gsub(/^ */, '')
      P2 4 2 100
      10 20 30 40
      50 60 70 80
    EOF
    expected = {
      :magic_number => 'P2',
      :width        => 4,
      :height       => 2,
      :maxgray      => 100,
      :data         => "10 20 30 40\n50 60 70 80"
    }

    @parser.parse(content).must_equal expected
  end

  it 'can parse binary encoded data' do
    content = 'P4 8 2 ' << ['05AF'].pack('H*')
    expected = {
      :magic_number => 'P4',
      :width        => 8,
      :height       => 2,
      :data         => ['05AF'].pack('H*')
    }

    @parser.parse(content).must_equal expected
  end

  it 'does not change the passed data' do
    content = 'P1 3 2 0 1 0 0 1 1'
    original_content = content.dup
    @parser.parse(content)

    content.must_equal original_content
  end

  it 'does accept multiple whitespace as delimiter' do
    content = "P1  \n\t 3 \r \n2 0 1 0 0 1 1"
    expected = {
      :magic_number => 'P1',
      :width        => 3,
      :height       => 2,
      :data         => '0 1 0 0 1 1'
    }

    @parser.parse(content).must_equal expected
  end

  it 'can parse binary encoded data including whitespace' do
    @parser.parse("P4 16 4 A\nB\rC D\t")[:data].must_equal "A\nB\rC D\t"
  end

  it 'can parse binary encoded data starting with whitespace' do
    @parser.parse("P4 8 2 \nA")[:data].must_equal "\nA"
  end

  it 'can parse binary encoded data starting with comment character' do
    @parser.parse("P4 8 2 #A")[:data].must_equal "#A"
  end

  it 'does not chomp newlines from parsed binary encoded data' do
    @parser.parse("P4 8 2 AB\n")[:data].must_equal "AB\n"
  end

  it 'can parse comments' do
    content =<<-EOF.chomp.gsub(/^ */, '')
      # Comment 1
      P1  # Comment 2
      6# Comment 3
      #Comment 4
      #
      \r \t# Comment 6
      2
      0 1 0 0 1 1
      0 0 0 1 1 1
    EOF
    expected = {
      :magic_number => 'P1',
      :width        => 6,
      :height       => 2,
      :comments     => ['Comment 1', 'Comment 2', 'Comment 3', 'Comment 4', '', 'Comment 6'],
      :data         => "0 1 0 0 1 1\n0 0 0 1 1 1"
    }

    @parser.parse(content).must_equal expected
  end
end
