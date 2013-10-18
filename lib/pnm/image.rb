module PNM

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
