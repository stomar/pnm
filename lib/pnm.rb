# = pnm.rb - create/read/write PNM image files (PBM, PGM, PPM)
#
# See PNM module for documentation.


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
  VERSION  = '0.0.0'
  DATE     = '2013-02-06'
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

  # Class for +PBM+, +PGM+, and +PPM+ images. See PNM module for examples.
  class Image

    attr_reader :type, :width, :height, :maxgray, :pixels

    # Create an image from an array of gray or RGB values.
    def initialize(type, pixels, options = {})
      @type    = type
      @width   = pixels.first.size
      @height  = pixels.size
      @maxgray = options[:maxgray] || 255
      @pixels  = pixels

      if type == :ppm && !pixels.first.first.kind_of?(Array)
        @pixels = pixels.map {|row| row.map {|pixel| gray_to_rgb(pixel) } }
      end
    end

    def write(file, encoding = :binary)
      content = if encoding == :ascii
                  to_ascii
                elsif encoding == :binary
                  to_binary
                end

      if file.kind_of?(String)
        File.open(file, 'wb') {|f| f.write content }
      else
        file.write content
      end
    end

    def info
      "#{type.to_s.upcase} #{width}x#{height} #{type_string}"
    end

    def to_s
      "#<#{self.class}:0x#{object_id.to_s(16)} #{info}>"
    end

    private

    def type_string
      case type
      when :pbm
        'Bilevel'
      when :pgm
        'Grayscale'
      when :ppm
        'Color'
      end
    end

    def header(encoding)
      header =  "#{PNM.magic_number[type][encoding]}\n#{width} #{height}\n"
      header << "#{maxgray}\n"  unless type == :pbm

      header
    end

    def to_ascii
      data_string = pixels.map {|row| row.flatten.join(' ') }.join("\n")

      header(:ascii) << data_string << "\n"
    end

    def to_binary
      raise NotImplementedError  if type == :pbm

      data_string = pixels.flatten.map {|pixel| pixel.chr }.join('')

      header(:binary) << data_string
    end

    def gray_to_rgb(gray_value)
      Array.new(3, gray_value)
    end
  end
end
