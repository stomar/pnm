module PNM

  # Class for +PBM+, +PGM+, and +PPM+ images. See PNM module for examples.
  class Image

    # The type of the image (+:pbm+, +:pgm+, or +:ppm+).
    attr_reader :type

    # The width of the image in pixels.
    attr_reader :width

    # The height of the image in pixels.
    attr_reader :height

    # The maximum gray or color value.
    # For PGM and PPM, +maxgray+ must be less or equal 255 (default value).
    attr_reader :maxgray

    # The pixel data, given as two-dimensional array of:
    #
    # * for PBM: values of 0 or 1,
    # * for PGM: values between 0 and +maxgray+,
    # * for PPM: an array of 3 values between 0 and +maxgray+,
    #   corresponding to red, green, and blue (RGB).
    #
    # A value of 0 means that the color is turned off.
    attr_reader :pixels

    # Creates an image from a two-dimensional array of gray or RGB values.
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

    # Writes the image to a file, using the specified encoding.
    # Valid encodings are +:binary+ (default) and +:ascii+.
    #
    # Returns the number of bytes written.
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

    # Returns a string with a short image format description.
    def info
      "#{type.to_s.upcase} #{width}x#{height} #{type_string}"
    end

    alias :to_s :info

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
      if type == :pbm
        if width % 8 == 0
          padding = []
        else
          padding = Array.new(8 - width % 8, 0)
        end
        padded_rows = pixels.map {|row| row + padding }
        byte_rows = padded_rows.map {|row| row.join.scan(/.{8}/) }

        data_string = byte_rows.flatten.map {|byte| byte.to_i(2).chr }.join
      else
        data_string = pixels.flatten.map {|pixel| pixel.chr }.join('')
      end

      header(:binary) << data_string
    end

    def gray_to_rgb(gray_value)
      Array.new(3, gray_value)
    end
  end
end
