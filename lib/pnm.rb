# = pnm.rb - create/read/write PNM image files (PBM, PGM, PPM)
#
# See PNM module for documentation.

require_relative 'pnm/version'
require_relative 'pnm/image'
require_relative 'pnm/parser'
require_relative 'pnm/converter'
require_relative 'pnm/exceptions'


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
#     require 'pnm'
#
#     # pixel data
#     pixels = [[ 0, 10, 20],
#               [10, 20, 30]]
#
#     # optional settings
#     options = {:maxgray => 30, :comment => 'Test Image'}
#
#     # create the image object
#     image = PNM::Image.new(pixels, options)
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
# See PNM::Image.new for a more detailed description of pixel data formats
# and available options.
#
# Write an image to a file:
#
#     image.write('test.pgm')
#
#     # use ASCII or "plain" format (default is binary)
#     image.write('test.pgm', :ascii)
#
#     # write to an I/O stream
#     File.open('test.pgm', 'w') {|f| image.write(f) }
#
# Read an image from a file (returns a PNM::Image object):
#
#     image = PNM.read('test.pgm')
#     image.comment  # => "Test Image"
#     image.maxgray  # => 30
#     image.pixels   # => [[0, 10, 20], [10, 20, 30]]
#
# Force an image type:
#
#     image = PNM::Image.new([[0, 1],[1, 0]], :type => :ppm)
#     image.info  # => "PPM 2x2 Color"
#
# == See also
#
# Further information on the PNM library is available on the
# project home page: <https://github.com/stomar/pnm/>.
#
# == Author
#
# Copyright (C) 2013-2014 Marcus Stollsteimer
#
# License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
#
module PNM

  LIBNAME  = 'pnm'
  HOMEPAGE = 'https://github.com/stomar/pnm'
  TAGLINE  = 'create/read/write PNM image files (PBM, PGM, PPM)'

  COPYRIGHT = <<-copyright.gsub(/^ +/, '')
    Copyright (C) 2013-2014 Marcus Stollsteimer.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
  copyright

  # Reads an image from +file+ (a filename or an IO object).
  #
  # Returns a PNM::Image object.
  def self.read(file)
    if file.kind_of?(String)
      raw_data = File.binread(file)
    elsif file.respond_to?(:binmode)
      file.binmode
      raw_data = file.read
    else
      raise PNM::ArgumentError, "wrong argument type"
    end

    content = Parser.parse(raw_data)

    case content[:magic_number]
    when 'P1'
      type = :pbm
      encoding = :ascii
    when 'P2'
      type = :pgm
      encoding = :ascii
    when 'P3'
      type = :ppm
      encoding = :ascii
    when 'P4'
      type = :pbm
      encoding = :binary
    when 'P5'
      type = :pgm
      encoding = :binary
    when 'P6'
      type = :ppm
      encoding = :binary
    end

    width   = content[:width]
    height  = content[:height]
    maxgray = content[:maxgray]
    pixels = if encoding == :ascii
               Converter.ascii2array(type, width, height, content[:data])
             else
               Converter.binary2array(type, width, height, content[:data])
             end

    options = {:type => type, :maxgray => maxgray}
    options[:comment] = content[:comments].join("\n")  if content[:comments]

    Image.new(pixels, options)
  end

  # @private
  def self.magic_number  # :nodoc:
    {
      :pbm => {:ascii => 'P1', :binary => 'P4'},
      :pgm => {:ascii => 'P2', :binary => 'P5'},
      :ppm => {:ascii => 'P3', :binary => 'P6'}
    }
  end
end
