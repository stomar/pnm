module PNM

  # Class for +PBM+, +PGM+, and +PPM+ images. See PNM module for examples.
  class Image

    # The type of the image. See ::new for details.
    attr_reader :type

    # The width of the image in pixels.
    attr_reader :width

    # The height of the image in pixels.
    attr_reader :height

    # The maximum gray or color value (for PBM always set to 1).
    # See ::new for details.
    attr_reader :maxgray

    # The pixel data, given as a two-dimensional array.
    # See ::new for details.
    attr_reader :pixels

    # An optional multiline comment string.
    attr_reader :comment

    # Creates an image from a two-dimensional array of bilevel,
    # gray, or RGB values.
    #
    # +pixels+::  The pixel data, given as a two-dimensional array of
    #
    #             * for PBM: bilevel values (0 or 1),
    #             * for PGM: gray values between 0 and +maxgray+,
    #             * for PPM: an array of 3 values between 0 and +maxgray+,
    #               corresponding to red, green, and blue (RGB).
    #
    #             PPM also accepts an array of bilevel or gray values.
    #
    #             A value of 0 means that the color is turned off.
    #
    # Optional settings that can be specified in the +options+ hash:
    #
    # +type+::    The type of the image (+:pbm+, +:pgm+, or +:ppm+).
    #             By default, the type is guessed from the provided
    #             pixel data, unless this option is used.
    # +maxgray+:: The maximum gray or color value.
    #             For PGM and PPM, +maxgray+ must be less or equal 255
    #             (the default value).
    #             For PBM pixel data, setting +maxgray+ implies a conversion
    #             to +:pgm+. If +type+ is explicitly set to +:pbm+,
    #             the +maxgray+ setting is disregarded.
    # +comment+:: A multiline comment string (default: empty string).
    def initialize(pixels, options = {})
      @type    = options[:type]
      @width   = pixels.first.size
      @height  = pixels.size
      @maxgray = options[:maxgray]
      @comment = (options[:comment] || '').chomp
      @pixels  = pixels.dup

      @type ||= detect_type(@pixels, @maxgray)

      if @type == :pbm
        @maxgray = 1
      else
        @maxgray ||= 255
      end

      if type == :ppm && !pixels.first.first.kind_of?(Array)
        @pixels.map! {|row| row.map {|pixel| gray_to_rgb(pixel) } }
      end
    end

    # Writes the image to +file+ (a filename or an IO object),
    # using the specified encoding.
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
        File.binwrite(file, content)
      else
        file.binmode
        file.write content
      end
    end

    # Returns a string with a short image format description.
    def info
      "#{type.to_s.upcase} #{width}x#{height} #{type_string}"
    end

    alias :to_s :info

    private

    def type_string  # :nodoc:
      case type
      when :pbm
        'Bilevel'
      when :pgm
        'Grayscale'
      when :ppm
        'Color'
      end
    end

    def detect_type(pixels, maxgray)  # :nodoc:
      if pixels.first.first.kind_of?(Array)
        :ppm
      elsif pixels.flatten.max <= 1
        maxgray ? :pgm : :pbm
      else
        :pgm
      end
    end

    def header(encoding)  # :nodoc:
      header =  "#{PNM.magic_number[type][encoding]}\n"
      if comment
        comment.split("\n").each {|line| header << "# #{line}\n" }
      end
      header << "#{width} #{height}\n"
      header << "#{maxgray}\n"  unless type == :pbm

      header
    end

    def to_ascii  # :nodoc:
      data_string = Converter.array2ascii(pixels)

      header(:ascii) << data_string
    end

    def to_binary  # :nodoc:
      data_string = Converter.array2binary(type, pixels)

      header(:binary) << data_string
    end

    def gray_to_rgb(gray_value)  # :nodoc:
      Array.new(3, gray_value)
    end
  end
end
