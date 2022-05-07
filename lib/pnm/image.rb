# frozen_string_literal: true

module PNM

  # Abstract base class for +PBM+, +PGM+, and +PPM+ images.
  #
  # Images can be created from pixel values, see PNM.create,
  # or read from a file or I/O stream, see PNM.read.
  #
  # See PNM module for examples.
  class Image

    # The type of the image. See PNM.create for details.
    def type
      # implemented by subclasses
    end

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
    def self.create(pixels, type: nil, maxgray: nil, comment: nil)
      assert_valid_array(pixels)
      assert_valid_maxgray(maxgray)
      assert_valid_comment(comment)

      type = sanitize_and_assert_valid_type(type)
      type ||= detect_type(pixels, maxgray)

      # except for type detection, the maxgray option must be ignored for PBM
      maxgray = if type == :pbm
                  nil
                else
                  maxgray
                end

      image_class = case type
                    when :pbm
                      PBMImage
                    when :pgm
                      PGMImage
                    when :ppm
                      PPMImage
                    end

      image_class.new(pixels, maxgray, comment)
    end

    class << self
      protected :new
    end

    # @private
    #
    # Invoked by ::create after basic input validations.
    def initialize(pixels, maxgray, comment)  # :nodoc:
      @pixels  = pixels.dup
      @width   = pixels.first.size
      @height  = pixels.size
      @maxgray = maxgray || default_maxgray
      @comment = comment

      assert_pixel_value_range

      post_initialize

      @pixels.freeze
      @comment.freeze
    end

    # Writes the image to +file+ (a filename or an IO object).
    #
    # When +add_extension+ is set to +true+ (default: +false+)
    # the appropriate file extension is added to the provided filename
    # (+.pbm+, +.pgm+, or +.ppm+).
    #
    # The encoding can be set using the +encoding+ keyword argument,
    # valid options are +:binary+ (default) and +:ascii+.
    #
    # Returns the number of bytes written.
    def write(file, add_extension: false, encoding: :binary)
      content = case encoding
                when :ascii
                  to_ascii
                when :binary
                  to_binary
                end

      if file.is_a?(String)
        filename = add_extension ? "#{file}.#{type}" : file
        File.binwrite(filename, content)
      else
        file.binmode
        file.write content
      end
    end

    # Returns a string with a short image format description.
    def info
      "#{type.to_s.upcase} #{width}x#{height} #{type_string}"
    end

    alias to_s info

    # Returns a string representation for debugging.
    def inspect
      # implemented by subclasses
    end

    # Equality --- Two images are considered equal if they have
    # the same pixel values, type, maxgray, and comments.
    def ==(other)
      return true  if other.equal?(self)
      return false  unless other.instance_of?(self.class)

      type == other.type && maxgray == other.maxgray && comment == other.comment && pixels == other.pixels
    end

    def self.assert_valid_array(pixels)  # :nodoc:
      assert_array_dimensions(pixels)
      assert_pixel_types(pixels)
    end
    private_class_method :assert_valid_array

    def self.assert_array_dimensions(pixels)  # :nodoc:
      msg = "invalid pixel data: Array expected"
      raise PNM::ArgumentError, msg  unless pixels.is_a?(Array)

      msg = "invalid pixel array"
      raise PNM::DataError, msg  unless pixels.map(&:class).uniq == [Array]

      width = pixels.first.size
      raise PNM::DataError, msg  if width.zero?
      raise PNM::DataError, msg  unless pixels.map(&:size).uniq == [width]
    end
    private_class_method :assert_array_dimensions

    def self.assert_pixel_types(pixels)  # :nodoc:
      pixel_values = pixels.flatten(1)
      is_color = pixel_values.first.is_a?(Array)

      if is_color
        pixel_values.each {|pixel| assert_valid_color_pixel(pixel) }
      else
        pixel_values.each {|pixel| assert_valid_pixel(pixel) }
      end
    end
    private_class_method :assert_pixel_types

    def self.assert_valid_pixel(pixel)  # :nodoc:
      return  if pixel.is_a?(Integer)

      msg = "invalid pixel value: Integer expected - #{pixel.inspect}"
      raise PNM::DataError, msg
    end
    private_class_method :assert_valid_pixel

    def self.assert_valid_color_pixel(pixel)  # :nodoc:
      return  if pixel.is_a?(Array) && pixel.size == 3 && pixel.all? {|p| p.is_a?(Integer) }

      msg =  "invalid pixel value: ".dup
      msg << "Array of 3 Integers expected - #{pixel.inspect}"
      raise PNM::DataError, msg
    end
    private_class_method :assert_valid_color_pixel

    def self.assert_valid_maxgray(maxgray)  # :nodoc:
      return  unless maxgray
      return  if maxgray.is_a?(Integer) && maxgray > 0 && maxgray <= 255

      msg = "invalid maxgray value - #{maxgray.inspect}"
      raise PNM::ArgumentError, msg
    end
    private_class_method :assert_valid_maxgray

    def self.assert_valid_comment(comment)  # :nodoc:
      return  unless comment
      return  if comment.is_a?(String)

      msg = "invalid comment value - #{comment.inspect}"
      raise PNM::ArgumentError, msg
    end
    private_class_method :assert_valid_comment

    def self.sanitize_and_assert_valid_type(type)  # :nodoc:
      return  unless type

      type = type.to_sym  if type.is_a?(String)

      unless %i[pbm pgm ppm].include?(type)
        msg = "invalid image type - #{type.inspect}"
        raise PNM::ArgumentError, msg
      end

      type
    end
    private_class_method :sanitize_and_assert_valid_type

    def self.detect_type(pixels, maxgray)  # :nodoc:
      if pixels.first.first.is_a?(Array)
        :ppm
      elsif (maxgray && maxgray > 1) || pixels.flatten.max > 1
        :pgm
      else
        :pbm
      end
    end
    private_class_method :detect_type

    private

    def assert_grayscale_data  # :nodoc:
      return  unless color_pixels?

      msg = "specified type does not match RGB data - #{type.inspect}"
      raise PNM::DataError, msg
    end

    def assert_pixel_value_range  # :nodoc:
      msg = "invalid data: value(s) greater than maxgray"
      raise PNM::DataError, msg  unless pixels.flatten.max <= maxgray

      msg = "invalid data: value(s) less than zero"
      raise PNM::DataError, msg  unless pixels.flatten.min >= 0
    end

    def header_without_maxgray(encoding)  # :nodoc:
      header = "#{PNM.magic_number[type][encoding]}\n".dup
      comment_lines.each do |line|
        header << (line.empty? ? "#\n" : "# #{line}\n")
      end
      header << "#{width} #{height}\n"

      header
    end

    def header_with_maxgray(encoding)  # :nodoc:
      header_without_maxgray(encoding) << "#{maxgray}\n"
    end

    def comment_lines  # :nodoc:
      return []    unless comment
      return [""]  if comment.empty?

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
      pixels.first.first.is_a?(Array)
    end

    def inspect_string_with_maxgray  # :nodoc:
      "#<%s:0x%x %s, maxgray=%d>" % [self.class.name, object_id, info, maxgray]
    end

    def inspect_string_without_maxgray  # :nodoc:
      "#<%s:0x%x %s>" % [self.class.name, object_id, info]
    end
  end


  # Class for +PBM+ images. See the Image class for documentation.
  class PBMImage < Image

    def type
      :pbm
    end

    def inspect
      inspect_string_without_maxgray
    end

    private

    def post_initialize  # :nodoc:
      assert_grayscale_data
    end

    def default_maxgray  # :nodoc:
      1
    end

    def type_string  # :nodoc:
      "Bilevel"
    end

    def header(encoding)  # :nodoc:
      header_without_maxgray(encoding)
    end
  end


  # Class for +PGM+ images. See the Image class for documentation.
  class PGMImage < Image

    def type
      :pgm
    end

    def inspect
      inspect_string_with_maxgray
    end

    private

    def post_initialize  # :nodoc:
      assert_grayscale_data
    end

    def default_maxgray  # :nodoc:
      255
    end

    def type_string  # :nodoc:
      "Grayscale"
    end

    def header(encoding)  # :nodoc:
      header_with_maxgray(encoding)
    end
  end


  # Class for +PPM+ images. See the Image class for documentation.
  class PPMImage < Image

    def type
      :ppm
    end

    def inspect
      inspect_string_with_maxgray
    end

    private

    def post_initialize  # :nodoc:
      convert_pixels_to_color  unless color_pixels?
    end

    def default_maxgray  # :nodoc:
      255
    end

    def type_string  # :nodoc:
      "Color"
    end

    def header(encoding)  # :nodoc:
      header_with_maxgray(encoding)
    end

    def convert_pixels_to_color  # :nodoc:
      pixels.map! {|row| row.map {|pixel| gray_to_rgb(pixel) } }
    end

    def gray_to_rgb(gray_value)  # :nodoc:
      Array.new(3, gray_value)
    end
  end
end
