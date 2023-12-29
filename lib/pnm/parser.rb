# frozen_string_literal: true

module PNM

  # @private
  # Parser for PNM image files. Only for internal usage.
  class Parser  # :nodoc:

    # Parses PNM image data.
    #
    # +content+:: A string containing the image file content.
    #
    # Returns a hash containing the parsed data:
    #
    # * +:magic_number+ (<tt>"P1"</tt>, ..., <tt>"P6"</tt>),
    # * +:maxgray+ (only for PGM and PPM),
    # * +:width+,
    # * +:height+,
    # * +:data+ (as string),
    # * +:comments+ (only if present): an array of comment strings.
    def self.parse(content)
      content = content.dup

      magic_number = nil
      tokens = []
      comments = []

      until magic_number
        token = next_token!(content)

        if token.start_with?("#")
          comments << token.gsub(/# */, "")
        else
          magic_number = token
        end
      end

      assert_valid_magic_number(magic_number)

      while tokens.size < token_number[magic_number]
        content.gsub!(/\A[ \t\r\n]+/, "")
        token = next_token!(content)

        if token.start_with?("#")
          comments << token.gsub(/# */, "")
        else
          tokens << token
        end
      end

      width, height, maxgray = tokens

      assert_integer(width, "width")
      assert_integer(height, "height")
      assert_integer(maxgray, "maxgray")  if maxgray

      width = width.to_i
      height = height.to_i
      maxgray = maxgray.to_i  if maxgray

      assert_positive(width, "width")
      assert_positive(height, "height")
      assert_in_maxgray_range(maxgray)  if maxgray

      result = {
        magic_number: magic_number,
        width:        width,
        height:       height,
        data:         content
      }
      result[:maxgray]  = maxgray   if maxgray
      result[:comments] = comments  unless comments.empty?

      result
    end

    def self.token_number
      {
        "P1" => 2,
        "P2" => 3,
        "P3" => 3,
        "P4" => 2,
        "P5" => 3,
        "P6" => 3
      }
    end

    def self.next_token!(content)
      delimiter = if content.start_with?("#")
                    "\n"
                  else
                    /[ \t\r\n]|(?=#)/
                  end

      token, rest = content.split(delimiter, 2)
      raise PNM::ParserError, "not enough tokens in file"  unless rest

      content.replace(rest)

      token
    end

    def self.assert_valid_magic_number(magic_number)
      return  if %w[P1 P2 P3 P4 P5 P6].include?(magic_number)

      msg = "unknown magic number - `#{magic_number}'"
      raise PNM::ParserError, msg
    end

    def self.assert_integer(value_string, value_name)
      return  if value_string =~ /\A[0-9]+\z/

      msg = "#{value_name} must be an integer - `#{value_string}'"
      raise PNM::ParserError, msg
    end

    def self.assert_positive(value, name)
      return  if value > 0

      msg = "#{name} must be greater than 0 - `#{value}'"
      raise PNM::ParserError, msg
    end

    def self.assert_in_maxgray_range(value)
      return  if value > 0 && value <= 255

      msg = "invalid maxgray value - `#{value}'"
      raise PNM::ParserError, msg
    end
  end
end
