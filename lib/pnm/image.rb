module PNM

  # Class for +PBM+, +PGM+, and +PPM+ images.
  #
  # Images can be created from pixel values, see ::new,
  # or read from a file or I/O stream, see PNM.read.
  #
  # See PNM module for examples.
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

    # An optional multiline comment string (or +nil+).
    attr_reader :comment

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
    # Optional settings that can be specified in the +options+ hash:
    #
    # +type+::    The type of the image (+:pbm+, +:pgm+, or +:ppm+).
    #             By explicitly setting +type+, PGM images can be
    #             created from bilevel pixel data, and PPM images can be
    #             created from bilevel or gray pixel data.
    # +maxgray+:: The maximum gray or color value.
    #             For PGM and PPM, +maxgray+ must be less or equal 255
    #             (the default value).
    #             For bilevel pixel data, setting +maxgray+ to a value
    #             greater than 1 implies a type of +:pgm+.
    #             When +type+ is explicitly set to +:pbm+,
    #             the +maxgray+ setting is disregarded.
    # +comment+:: A multiline comment string.
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

    # Returns a string representation for debugging.
    def inspect
      if type == :pbm
        "#<%s:0x%x %s>" % [self.class.name, object_id, info]
      else
        "#<%s:0x%x %s, maxgray=%d>" % [self.class.name, object_id, info, maxgray]
      end
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

    def detect_type(pixels, maxgray)
      if pixels.first.first.kind_of?(Array)
        :ppm
      elsif (maxgray && maxgray > 1) || pixels.flatten.max > 1
        :pgm
      else
        :pbm
      end
    end

    def assert_valid_array
      msg = "invalid pixel data: Array expected"
      raise PNM::ArgumentError, msg  unless Array === pixels

      msg = "invalid pixel array"
      raise PNM::DataError, msg  unless Array === pixels.first

      width = pixels.first.size
      is_color = (Array === pixels.first.first)

      pixels.each do |row|
        raise PNM::DataError, msg  unless Array === row && row.size == width

        if is_color
          row.each {|pixel| assert_valid_color_pixel(pixel) }
        else
          row.each {|pixel| assert_valid_pixel(pixel) }
        end
      end
    end

    def assert_valid_pixel(pixel)
      unless Fixnum === pixel
        msg = "invalid pixel value: Fixnum expected - #{pixel.inspect}"
        raise PNM::DataError, msg
      end
    end

    def assert_valid_color_pixel(pixel)
      unless Array === pixel && pixel.map(&:class) == [Fixnum, Fixnum, Fixnum]
        msg =  "invalid pixel value: "
        msg << "Array of 3 Fixnums expected - #{pixel.inspect}"

        raise PNM::DataError, msg
      end
    end

    def assert_valid_type
      unless [:pbm, :pgm, :ppm].include?(type)
        msg = "invalid image type - #{type.inspect}"
        raise PNM::ArgumentError, msg
      end
    end

    def assert_matching_type_and_data
      if Array === pixels.first.first && [:pbm, :pgm].include?(type)
        msg = "specified type does not match data - #{type.inspect}"
        raise PNM::DataError, msg
      end
    end

    def assert_valid_maxgray
      unless Fixnum === maxgray && maxgray > 0 && maxgray <= 255
        raise PNM::ArgumentError, "invalid maxgray value - #{maxgray.inspect}"
      end
    end

    def assert_valid_comment
      unless String === comment
        raise PNM::ArgumentError, "invalid comment value - #{comment.inspect}"
      end
    end

    def assert_valid_pixel_values
      unless pixels.flatten.max <= maxgray
        raise PNM::DataError, "invalid data: value(s) greater than maxgray"
      end
      unless pixels.flatten.min >= 0
        raise PNM::DataError, "invalid data: value(s) less than zero"
      end
    end

    def header(encoding)
      header =  "#{PNM.magic_number[type][encoding]}\n"
      comment_lines.each do |line|
        header << (line.empty? ? "#\n" : "# #{line}\n")
      end
      header << "#{width} #{height}\n"
      header << "#{maxgray}\n"  unless type == :pbm

      header
    end

    def comment_lines
      return []    unless comment
      return ['']  if comment.empty?

      keep_trailing_null_fields = -1  # magic value for split limit
      comment.split(/\n/, keep_trailing_null_fields)
    end

    def to_ascii
      data_string = Converter.array2ascii(pixels)

      header(:ascii) << data_string
    end

    def to_binary
      data_string = Converter.array2binary(type, pixels)

      header(:binary) << data_string
    end

    def gray_to_rgb(gray_value)
      Array.new(3, gray_value)
    end
  end
end
