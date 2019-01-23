#!/usr/bin/env ruby
# frozen_string_literal: true

# bm_converter.rb: Benchmarks for the PNM library.
#
# Copyright (C) 2013-2019 Marcus Stollsteimer

require "benchmark"
require_relative "../lib/pnm"

class ConverterBenchmark

  def initialize
    @repetitions = ARGV[0].to_i  if ARGV[0] =~ /[0-9]+/
    @repetitions ||= 10

    @srcpath = File.dirname(__FILE__)

    print "Initializing test data..."
    @pbm_image = PNM.read(File.expand_path("#{@srcpath}/random_image.pbm"))
    @pgm_image = PNM.read(File.expand_path("#{@srcpath}/random_image.pgm"))
    @ppm_image = PNM.read(File.expand_path("#{@srcpath}/random_image.ppm"))
    puts " done\n"

    @user   = 0.0
    @system = 0.0
    @total  = 0.0
  end

  def run
    puts "Running benchmarks (#{@repetitions} repetitions)..."

    run_benchmark(@pbm_image)
    run_benchmark(@pgm_image)
    run_benchmark(@ppm_image)

    puts "\nTotal:               ".dup <<
         @user.round(2).to_s.ljust(11) <<
         @system.round(2).to_s.ljust(11) <<
         @total.round(2).to_s
  end

  def run_benchmark(image)
    type   = image.type
    width  = image.width
    height = image.height
    array  = image.pixels
    ascii  = PNM::Converter.array2ascii(array)
    binary = PNM::Converter.array2binary(type, array)
    type_string = type.upcase

    puts

    Benchmark.bm(18) do |bm|
      bm.report("#{type_string} / ascii2array") {
        @repetitions.times do
          PNM::Converter.ascii2array(type, width, height, ascii)
        end
      }

      bm.report("#{type_string} / array2ascii") {
        @repetitions.times do
          PNM::Converter.array2ascii(array)
        end
      }

      bm.report("#{type_string} / binary2array") {
        @repetitions.times do
          PNM::Converter.binary2array(type, width, height, binary)
        end
      }

      bm.report("#{type_string} / array2binary") {
        @repetitions.times do
          PNM::Converter.array2binary(type, array)
        end
      }

      @user   += bm.list.map {|tms| tms.utime }.reduce(:+)
      @system += bm.list.map {|tms| tms.stime }.reduce(:+)
      @total  += bm.list.map {|tms| tms.total }.reduce(:+)
    end
  end
end

ConverterBenchmark.new.run
