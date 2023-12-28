# frozen_string_literal: true

# = pnm.rb - create/read/write PNM image files (PBM, PGM, PPM)
#
# See PNM module for documentation.

require_relative "pnm/version"
require_relative "pnm/image"
require_relative "pnm/parser"
require_relative "pnm/converter"
require_relative "pnm/exceptions"


# PNM is a pure Ruby library for creating, reading,
# and writing of +PNM+ image files (Portable Anymap):
#
# - +PBM+ (Portable Bitmap),
# - +PGM+ (Portable Graymap), and
# - +PPM+ (Portable Pixmap).
#
# It is a portable and lightweight utility for exporting or importing
# of raw pixel data to or from an image file format that can be processed
# by most image manipulation programs.
#
# PNM comes without any dependencies on other gems or native libraries.
#
# == Examples
#
# Create a PGM grayscale image from a two-dimensional array of gray values:
#
#     require "pnm"
#
#     # pixel data
#     pixels = [[ 0, 10, 20],
#               [10, 20, 30]]
#
#     # create the image object
#     image = PNM.create(pixels)
#
#     # create the image with additional optional settings
#     image = PNM.create(pixels, maxgray: 30, comment: "Test Image")
#
#     # retrieve some image properties
#     image.info    # => "PGM 3x2 Grayscale"
#     image.type    # => :pgm
#     image.width   # => 3
#     image.height  # => 2
#
# Note that for PBM bilevel images a pixel value of 0 signifies white
# (and 1 signifies black), whereas for PGM and PPM images a value of 0
# signifies black.
#
# See PNM.create for a more detailed description of pixel data formats
# and available options.
#
# Write an image to a file:
#
#     image.write("test.pgm")
#     image.write("test", add_extension: true)  # adds the appropriate file extension
#
#     # use ASCII or "plain" format (default is :binary)
#     image.write("test.pgm", encoding: :ascii)
#
#     # write to an I/O stream
#     File.open("test.pgm", "w") {|f| image.write(f) }
#
# Read an image from a file (returns a PNM::Image object):
#
#     image = PNM.read("test.pgm")
#     image.comment  # => "Test Image"
#     image.maxgray  # => 30
#     image.pixels   # => [[0, 10, 20], [10, 20, 30]]
#
# Force an image type:
#
#     color_image = PNM.create([[0, 1],[1, 0]], type: :ppm)
#     color_image.info  # => "PPM 2x2 Color"
#
# Check equality of two images:
#
#     color_image == image  # => false
#
# == See also
#
# Further information on the PNM library is available on the
# project home page: <https://github.com/stomar/pnm/>.
#
# == Author
#
# Copyright (C) 2013-2023 Marcus Stollsteimer
#
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
#
module PNM

  LIBNAME  = "pnm"
  HOMEPAGE = "https://github.com/stomar/pnm"
  TAGLINE  = "create/read/write PNM image files (PBM, PGM, PPM)"

  COPYRIGHT = <<~TEXT
    Copyright (C) 2013-2023 Marcus Stollsteimer.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
  TEXT

  # Reads an image from +file+ (a filename or an IO object).
  #
  # Returns a PNM::Image object.
  def self.read(file)
    if file.is_a?(String)
      raw_data = File.binread(file)
    elsif file.respond_to?(:binmode)
      file.binmode
      raw_data = file.read
    else
      raise PNM::ArgumentError, "wrong argument type"
    end

    content = Parser.parse(raw_data)

    type, encoding = type_and_encoding[content[:magic_number]]

    width   = content[:width]
    height  = content[:height]
    maxgray = content[:maxgray]
    pixels = if encoding == :ascii
               Converter.ascii2array(type, width, height, content[:data])
             else
               Converter.binary2array(type, width, height, content[:data])
             end

    comment = content[:comments].join("\n")  if content[:comments]

    create(pixels, type: type, maxgray: maxgray, comment: comment)
  end

  # Creates an image from a two-dimensional array of bilevel,
  # gray, or RGB values.
  # The image type is guessed from the provided pixel data,
  # unless it is explicitly set with the +type+ option.
  #
  # +pixels+::  The pixel data, given as a two-dimensional array of
  #
  #             * for PBM: bilevel values of 0 (white) or 1 (black),
  #             * for PGM: gray values between 0 (black) and +maxgray+ (white),
  #             * for PPM: an array of 3 values between 0 and +maxgray+,
  #               corresponding to red, green, and blue (RGB);
  #               a value of 0 means that the color is turned off.
  #
  # Optional settings:
  #
  # +type+::    The type of the image (+:pbm+, +:pgm+, or +:ppm+).
  #             By explicitly setting +type+, PGM images can be
  #             created from bilevel pixel data, and PPM images can be
  #             created from bilevel or gray pixel data.
  #             String values (<tt>"pbm"</tt>, <tt>"pgm"</tt>,
  #             or <tt>"ppm"</tt>) are also accepted.
  # +maxgray+:: The maximum gray or color value.
  #             For PGM and PPM, +maxgray+ must be less or equal 255
  #             (the default value).
  #             For bilevel pixel data, setting +maxgray+ to a value
  #             greater than 1 implies a type of +:pgm+.
  #             When +type+ is explicitly set to +:pbm+,
  #             the +maxgray+ setting is disregarded.
  # +comment+:: A multiline comment string.
  #
  # Returns a PNM::Image object.
  def self.create(pixels, type: nil, maxgray: nil, comment: nil)
    Image.create(pixels, type: type, maxgray: maxgray, comment: comment)
  end

  # @private
  def self.magic_number  # :nodoc:
    {
      pbm: { ascii: "P1", binary: "P4" },
      pgm: { ascii: "P2", binary: "P5" },
      ppm: { ascii: "P3", binary: "P6" }
    }
  end

  # @private
  def self.type_and_encoding  # :nodoc:
    {
      "P1" => %i[pbm ascii],
      "P2" => %i[pgm ascii],
      "P3" => %i[ppm ascii],
      "P4" => %i[pbm binary],
      "P5" => %i[pgm binary],
      "P6" => %i[ppm binary]
    }
  end
end
