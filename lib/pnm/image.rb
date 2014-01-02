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
    # +comment+:: A multiline comment string (or +nil+).
    def initialize(pixels, options = {})
      @type    = options[:type]
      @maxgray = options[:maxgray]
      @comment = options[:comment]
      @pixels  = pixels.dup

      assert_valid_type     if @type
      assert_valid_maxgray  if @maxgray
      assert_valid_comment  if @comment
      assert_valid_array

      @width   = pixels.first.size
      @height  = pixels.size

      @type ||= detect_type(@pixels, @maxgray)

      assert_matching_type_and_data

      if @type == :pbm
        @maxgray = 1
      else
        @maxgray ||= 255
      end

      assert_valid_pixel_values

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

    def assert_valid_array  # :nodoc:
      msg = "invalid pixel data: Array expected"
      raise PNM::ArgumentError, msg  unless Array === pixels

      msg = "invalid pixel array"
      raise PNM::DataError, msg  unless Array === pixels.first

      width = pixels.first.size

      pixels.each do |row|
        raise PNM::DataError, msg  unless Array === row && row.size == width

        if Array === row.first  # color image
          row.each {|pixel| assert_valid_color_pixel(pixel) }
        else
          row.each {|pixel| assert_valid_pixel(pixel) }
        end
      end
    end

    def assert_valid_pixel(pixel)  # :nodoc:
      msg = "invalid pixel value: Fixnum expected - %s"
      raise PNM::DataError, msg % pixel.inspect  unless Fixnum === pixel
    end

    def assert_valid_color_pixel(pixel)  # :nodoc:
      msg = "invalid pixel value: array of 3 Fixnums expected - %s"

      raise PNM::DataError, msg % pixel.inspect  unless pixel.size == 3
      raise PNM::DataError, msg % pixel.inspect  unless pixel.map {|val| val.class } == [Fixnum, Fixnum, Fixnum]
    end

    def assert_valid_type  # :nodoc:
      unless [:pbm, :pgm, :ppm].include?(type)
        msg = "invalid image type - %s"
        raise PNM::ArgumentError, msg % type.inspect
      end
    end

    def assert_matching_type_and_data  # :nodoc:
      if Array === pixels.first.first && [:pbm, :pgm].include?(type)
        msg = "specified type does not match data - %s"
        raise PNM::DataError, msg % type.inspect
      end
    end

    def assert_valid_maxgray  # :nodoc:
      unless Fixnum === maxgray && maxgray > 0 && maxgray <= 255
        raise PNM::ArgumentError, "invalid maxgray value - #{maxgray.inspect}"
      end
    end

    def assert_valid_comment  # :nodoc:
      unless String === comment
        raise PNM::ArgumentError, "invalid comment value - #{comment.inspect}"
      end
    end

    def assert_valid_pixel_values  # :nodoc:
      unless pixels.flatten.max <= maxgray
        raise PNM::DataError, "invalid data: value(s) greater than maxgray"
      end
      unless pixels.flatten.min >= 0
        raise PNM::DataError, "invalid data: value(s) less than zero"
      end
    end

    def header(encoding)  # :nodoc:
      header =  "#{PNM.magic_number[type][encoding]}\n"
      comment_lines.each do |line|
        header << (line.empty? ? "#\n" : "# #{line}\n")
      end
      header << "#{width} #{height}\n"
      header << "#{maxgray}\n"  unless type == :pbm

      header
    end

    def comment_lines  # :nodoc:
      return []    unless comment
      return ['']  if comment.empty?

      keep_trailing_null_fields = -1  # magic value for split limit
      comment.split(/\n/, keep_trailing_null_fields)
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
