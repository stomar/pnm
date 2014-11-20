module PNM

  # Converter for pixel data. Only for internal usage.
  class Converter  # :nodoc:

    # Returns the number of bytes needed for one row of pixels
    # (in binary encoding).
    def self.byte_width(type, width)
      case type
      when :pbm
        (width - 1) / 8 + 1
      when :pgm
        width
      when :ppm
        3 * width
      end
    end

    # Converts from ASCII format to an array of pixel values.
    #
    # +type+:: +:pbm+, +:pgm+, or +:ppm+.
    # +width+, +height+:: The image dimensions in pixels.
    # +data+:: A string containing the raw pixel data in ASCII format.
    #
    # Returns a two-dimensional array of bilevel, gray, or RGB values.
    def self.ascii2array(type, width, height, data)
      values_per_row = type == :ppm ? 3 * width : width

      values = convert_to_integers(data, type)
      assert_data_size(values.size, values_per_row * height)

      case type
      when :pbm, :pgm
        pixel_matrix = values.each_slice(width).to_a
      when :ppm
        pixel_matrix = values.each_slice(3 * width).map {|row| row.each_slice(3).to_a }
      end

      pixel_matrix
    end

    # Converts from binary format to an array of pixel values.
    #
    # +type+::            +:pbm+, +:pgm+, or +:ppm+.
    # +width+, +height+:: The image dimensions in pixels.
    # +data+::            A string containing the raw pixel data in binary format.
    #
    # Returns a two-dimensional array of bilevel, gray, or RGB values.
    def self.binary2array(type, width, height, data)
      bytes_per_row = byte_width(type, width)

      if data.size == bytes_per_row * height + 1 && data[-1] =~ /[ \t\r\n]/
        data.slice!(-1)
      end

      assert_data_size(data.size, bytes_per_row * height)

      case type
      when :pbm
        rows = data.scan(/.{#{bytes_per_row}}/m)
        pixel_matrix = rows.map {|row| row.unpack('B*').first[0, width].each_char.map {|char| char.to_i } }
      when :pgm
        pixel_matrix = data.each_byte.each_slice(bytes_per_row).to_a
      when :ppm
        pixel_matrix = data.each_byte.each_slice(bytes_per_row).map {|row| row.each_slice(3).to_a }
      end

      pixel_matrix
    end

    # Converts a two-dimensional array of pixel values to an ASCII format string.
    #
    # +data+:: A two-dimensional array of bilevel, gray, or RGB values.
    #
    # Returns a string containing the pixel data in ASCII format.
    def self.array2ascii(data)
      case data.first.first
      when Array
        data_string = data.map {|row| row.flatten.join(' ') }.join("\n")
      else
        data_string = data.map {|row| row.join(' ') }.join("\n")
      end

      data_string << "\n"
    end

    # Converts a two-dimensional array of pixel values to a binary format string.
    #
    # +type+:: +:pbm+, +:pgm+, or +:ppm+.
    # +data+:: A two-dimensional array of bilevel, gray, or RGB values.
    #
    # Returns a string containing the pixel data in binary format.
    def self.array2binary(type, data)
      height = data.size

      if type == :pbm
        binary_rows = data.map {|row| row.join }
        data_string = binary_rows.pack('B*' * height)
      else
        data_string = data.flatten.pack('C*')
      end

      data_string
    end

    def self.convert_to_integers(data, type)
      if type == :pbm
        values_as_string = data.gsub(/[ \t\r\n]+/, '').split('')
      else
        values_as_string = data.gsub(/\A[ \t\r\n]+/, '').split(/[ \t\r\n]+/)
      end

      values_as_string.map do |value|
        Integer(value)
      end
    rescue ::ArgumentError => e
      if e.message.start_with?('invalid value for Integer')
        raise PNM::DataError, "invalid pixel value: Integer expected"
      else
        raise
      end
    end

    def self.assert_data_size(actual, expected)
      unless actual == expected
        raise PNM::DataSizeError, 'data size does not match expected size'
      end
    end
  end
end
