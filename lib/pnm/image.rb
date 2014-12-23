module PNM

  # Class for +PBM+, +PGM+, and +PPM+ images.
  #
  # Images can be created from pixel values, see PNM.create,
  # or read from a file or I/O stream, see PNM.read.
  #
  # See PNM module for examples.
  class Image

    # The type of the image. See PNM.create for details.
    attr_reader :type

    # The width of the image in pixels.
    attr_reader :width

    # The height of the image in pixels.
    attr_reader :height

    # The maximum gray or color value (for PBM always set to 1).
    # See PNM.create for details.
    attr_reader :maxgray

    # The pixel data, given as a two-dimensional array.
    # See PNM.create for details.
    attr_reader :pixels

    # An optional multiline comment string (or +nil+).
    attr_reader :comment

    # Creates an image from a two-dimensional array of bilevel,
    # gray, or RGB values.
    #
    # This method should be called as PNM.create.
    # See there for a description of pixel data formats
    # and available options.
    def self.create(pixels, options = {})
      assert_valid_array(pixels)
      assert_valid_maxgray(options[:maxgray])
      assert_valid_comment(options[:comment])

      type = sanitize_and_assert_valid_type(options[:type])
      type ||= detect_type(pixels, options[:maxgray])

      # except for type detection, the maxgray option must be ignored for PBM
      if type == :pbm
        maxgray = nil
      else
        maxgray = options[:maxgray]
      end

      new(type, pixels, maxgray, options[:comment])
    end

    private_class_method :new

    # @private
    #
    # Invoked by ::create after basic input validations.
    def initialize(type, pixels, maxgray, comment)  # :nodoc:
      @type    = type
      @pixels  = pixels.dup
      @width   = pixels.first.size
      @height  = pixels.size
      @maxgray = maxgray || default_maxgray
      @comment = comment

      assert_valid_pixel_values
      assert_matching_type_and_data

      if type == :ppm && !color_pixels?
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

    def self.assert_valid_array(pixels)  # :nodoc:
      assert_array_dimensions(pixels)
      assert_pixel_types(pixels)
    end

    def self.assert_array_dimensions(pixels)  # :nodoc:
      msg = "invalid pixel data: Array expected"
      raise PNM::ArgumentError, msg  unless Array === pixels

      msg = "invalid pixel array"

      raise PNM::DataError, msg  unless pixels.map(&:class).uniq == [Array]
      width = pixels.first.size
      raise PNM::DataError, msg  unless pixels.map(&:size).uniq == [width]
    end

    def self.assert_pixel_types(pixels)  # :nodoc:
      pixel_values = pixels.flatten(1)
      is_color = (Array === pixel_values.first)

      if is_color
        pixel_values.each {|pixel| assert_valid_color_pixel(pixel) }
      else
        pixel_values.each {|pixel| assert_valid_pixel(pixel) }
      end
    end

    def self.assert_valid_pixel(pixel)  # :nodoc:
      unless Fixnum === pixel
        msg = "invalid pixel value: Fixnum expected - #{pixel.inspect}"
        raise PNM::DataError, msg
      end
    end

    def self.assert_valid_color_pixel(pixel)  # :nodoc:
      unless Array === pixel && pixel.map(&:class) == [Fixnum, Fixnum, Fixnum]
        msg =  "invalid pixel value: "
        msg << "Array of 3 Fixnums expected - #{pixel.inspect}"

        raise PNM::DataError, msg
      end
    end

    def self.assert_valid_maxgray(maxgray)  # :nodoc:
      return  unless maxgray

      unless Fixnum === maxgray && maxgray > 0 && maxgray <= 255
        raise PNM::ArgumentError, "invalid maxgray value - #{maxgray.inspect}"
      end
    end

    def self.assert_valid_comment(comment)  # :nodoc:
      return  unless comment

      unless String === comment
        raise PNM::ArgumentError, "invalid comment value - #{comment.inspect}"
      end
    end

    def self.sanitize_and_assert_valid_type(type)  # :nodoc:
      return  unless type

      type = type.to_sym  if type.kind_of?(String)

      unless [:pbm, :pgm, :ppm].include?(type)
        msg = "invalid image type - #{type.inspect}"
        raise PNM::ArgumentError, msg
      end

      type
    end

    def self.detect_type(pixels, maxgray)  # :nodoc:
      if pixels.first.first.kind_of?(Array)
        :ppm
      elsif (maxgray && maxgray > 1) || pixels.flatten.max > 1
        :pgm
      else
        :pbm
      end
    end

    def assert_matching_type_and_data  # :nodoc:
      if (type == :pbm || type == :pgm) && color_pixels?
        msg = "specified type does not match data - #{type.inspect}"
        raise PNM::DataError, msg
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

    def default_maxgray  # :nodoc:
      if type == :pbm
        1
      else
        255
      end
    end

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

    def color_pixels?  # :nodoc:
      (pixels.first.first).kind_of?(Array)
    end

    def gray_to_rgb(gray_value)  # :nodoc:
      Array.new(3, gray_value)
    end
  end
end
