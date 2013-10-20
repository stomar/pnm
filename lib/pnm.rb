# = pnm.rb - create/read/write PNM image files (PBM, PGM, PPM)
#
# See PNM module for documentation.

require_relative 'pnm/version'
require_relative 'pnm/image'
require_relative 'pnm/parser'
require_relative 'pnm/converter'


# PNM is a pure Ruby library for creating, reading,
# and writing of +PNM+ image files (Portable AnyMap):
#
# - +PBM+ (Portable Bitmap),
# - +PGM+ (Portable Graymap), and
# - +PPM+ (Portable Pixmap).
#
# == Examples
#
# Create an image from an array of gray values:
#
#     require 'pnm'
#
#     pixels = [[0, 1, 2],
#               [1, 2, 3]]
#     image = PNM::Image.new(:pgm, pixels, {:maxgray => 3})
#
# Write an image to a file:
#
#     image.write('test.pgm')
#
# Read an image from a file:
#
#     image = PNM.read('test.pgm')
#     image.info     # => "PGM 3x2 Grayscale"
#     image.maxgray  # => 3
#     image.pixels   # => [[0, 1, 2], [1, 2, 3]]
#
# == See also
#
# Further information on the PNM library is available on the
# project home page: <https://github.com/stomar/pnm/>.
#
# == Author
#
# Copyright (C) 2013 Marcus Stollsteimer
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
    Copyright (C) 2012-2013 Marcus Stollsteimer.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
  copyright

  # Reads an image file.
  #
  # So far only ASCII encoded image files can be handled.
  #
  # Returns a PNM::Image object.
  def self.read(file)
    raw_data = nil
    if file.kind_of?(String)
      File.open(file, 'rb') {|f| raw_data = f.read }
    else
      raw_data = file.read
    end

    content = Parser.parse(raw_data)

    case content[:magic_number]
    when 'P1'
      type = :pbm
    when 'P2'
      type = :pgm
    when 'P3'
      type = :ppm
    when 'P4'
      type = :pbm
      raise NotImplementedError
    when 'P5'
      type = :pgm
      raise NotImplementedError
    when 'P6'
      type = :ppm
      raise NotImplementedError
    end

    maxgray = content[:maxgray].to_i
    pixels = Converter.ascii2array(type, content[:data])

    Image.new(type, pixels, {:maxgray => maxgray})
  end

  def self.magic_number  # :nodoc:
    {
      :pbm => {:ascii => 'P1', :binary => 'P4'},
      :pgm => {:ascii => 'P2', :binary => 'P5'},
      :ppm => {:ascii => 'P3', :binary => 'P6'}
    }
  end
end
