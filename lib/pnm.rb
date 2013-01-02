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
#     image.width   # => 3
#     image.height  # => 2
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
#--
#
# == PNM magic numbers
#
#  Magic Number  Type              Encoding
#  ------------  ----------------  -------
#  P1            Portable bitmap   ASCII
#  P2            Portable graymap  ASCII
#  P3            Portable pixmap   ASCII
#  P4            Portable bitmap   Binary
#  P5            Portable graymap  Binary
#  P6            Portable pixmap   Binary
#
#++
#
module PNM

  LIBNAME  = 'pnm'                                                # :nodoc:
  HOMEPAGE = 'https://github.com/stomar/pnm'                      # :nodoc:
  TAGLINE  = 'create/read/write PNM image files (PBM, PGM, PPM)'  # :nodoc:

  COPYRIGHT = <<-copyright.gsub(/^ +/, '')                        # :nodoc:
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
    else
      file.binmode
      raw_data = file.read
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

  def self.magic_number  # :nodoc:
    {
      :pbm => {:ascii => 'P1', :binary => 'P4'},
      :pgm => {:ascii => 'P2', :binary => 'P5'},
      :ppm => {:ascii => 'P3', :binary => 'P6'}
    }
  end
end
