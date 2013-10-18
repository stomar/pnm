# = pnm.rb - create/read/write PNM image files (PBM, PGM, PPM)
#
# See PNM module for documentation.

require_relative 'pnm/version'
require_relative 'pnm/image'


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
#     pixels = [[0, 1, 2], [1, 2, 3]]
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

  LIBNAME  = 'pnm'
  HOMEPAGE = 'https://github.com/stomar/pnm'
  TAGLINE  = 'create/read/write PNM image files (PBM, PGM, PPM)'

  COPYRIGHT = <<-copyright.gsub(/^ +/, '')
    Copyright (C) 2012-2013 Marcus Stollsteimer.
    License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.
    This is free software: you are free to change and redistribute it.
    There is NO WARRANTY, to the extent permitted by law.
  copyright

  # Read an image file.
  #
  # At the moment, only ASCII encoded PGM files without comments
  # can be handled.
  def self.read(file)
    content = nil
    if file.kind_of?(String)
      File.open(file, 'rb') {|f| content = f.read }
    else
      content = file.read
    end

    magic_string = content[0..1]

    case magic_string
    when 'P1', 'P3', 'P4', 'P5', 'P6'
      raise NotImplementedError
    when 'P2'
      type = :pgm
      #encoding = :ascii
    end

    # _, _, _ = magic, width, height
    _, _, _, maxgray, data = content.split(/[ \t\r\n]+/, 5)

    pixels = data.split("\n").map do |row|
      row.split(/ +/).map {|value| value.to_i }
    end

    Image.new(type, pixels, {:maxgray => maxgray.to_i})
  end

  def self.magic_number  # :nodoc:
    {
      :pbm => {:ascii => 'P1', :binary => 'P4'},
      :pgm => {:ascii => 'P2', :binary => 'P5'},
      :ppm => {:ascii => 'P3', :binary => 'P6'}
    }
  end
end