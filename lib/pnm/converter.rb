module PNM

  # Converter for pixel data. Only for internal usage.
  class Converter

    # Converts from ASCII format to an array of pixel values.
    #
    # +type+ - +:pbm+, +:pgm+, or +:ppm+.
    # +data+ - A string containing the raw pixel data in ASCII format.
    #
    # Returns a two-dimensional array of gray or RGB values.
    def self.ascii2array(type, data)
      pixels = data.dup.split("\n").map do |row|
        row.split(/ +/).map {|value| value.to_i }
      end

      pixels.map! {|row| row.each_slice(3).to_a }  if type == :ppm

      pixels
    end

    # Converts from binary format to an array of pixel values.
    #
    # +type+  - +:pbm+, +:pgm+, or +:ppm+.
    # +width+, +height+ - The image dimensions in pixels.
    # +data+  - A string containing the raw pixel data in binary format.
    #
    # Returns a two-dimensional array of gray or RGB values.
    def self.binary2array(type, width, height, data)
      bytes_per_row = case type
                      when :pbm
                        (width - 1) / 8 + 1
                      when :pgm
                        width
                      when :ppm
                        3 * width
                      end

      if data.size == bytes_per_row * height + 1 && data[-1] =~ /[ \n\t\r]/
        data.slice!(-1)
      end

      if data.size != bytes_per_row * height
        raise 'data size does not match expected size'
      end

      pixels = data.each_byte.each_slice(bytes_per_row).to_a

      if type == :pbm
        pixels.map! {|row| byterow_to_bitrow(row)[0..(width - 1)] }
      elsif type == :ppm
        pixels.map! {|row| row.each_slice(3).to_a }
      end

      pixels
    end

    # Converts a two-dimensional array of pixel values to an ASCII format string.
    #
    # +data+  - A two-dimensional array of gray or RGB values.
    #
    # Returns a string containing the pixel data in ASCII format.
    def self.array2ascii(data)
      output = data.map {|row| row.flatten.join(' ') }.join("\n")

      output << "\n"
    end

    # Converts a two-dimensional array of pixel values to a binary format string.
    #
    # +type+  - +:pbm+, +:pgm+, or +:ppm+.
    # +data+  - A two-dimensional array of gray or RGB values.
    #
    # Returns a string containing the pixel data in binary format.
    def self.array2binary(type, data)
      width  = data.first.size
      height = data.size

      if type == :pbm
        if width % 8 == 0
          padding = []
        else
          padding = Array.new(8 - width % 8, 0)
        end
        padded_rows = data.map {|row| row + padding }
        byte_rows = padded_rows.map {|row| row.join.scan(/.{8}/) }

        data_string = byte_rows.flatten.map {|byte| byte.to_i(2).chr }.join
      else
        data_string = data.flatten.map {|pixel| pixel.chr }.join('')
      end

      data_string
    end

    def self.byterow_to_bitrow(byterow)  # :nodoc:
      byterow.map {|byte| byte.to_s(2).rjust(8, '0').each_char.map {|c| c.to_i } }.flatten
    end
  end
end
