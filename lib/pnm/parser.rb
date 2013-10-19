module PNM

  # Parser for PNM image files. Only for internal usage.
  class Parser

    # Parses PNM image data.
    #
    # +content+ - A string containing the image file content.
    #
    # Returns a hash containing the parsed data as strings:
    #
    # * +:magic_number+
    # * +:maxgray+ (only for PGM and PPM)
    # * +:width+
    # * +:height+
    # * +:data+
    # * +:comments+ (only if present): an array of comment strings
    def self.parse(content)
      content = content.dup

      magic_number = nil
      tokens   = []
      comments = []

      until magic_number
        token = get_next_token!(content)

        if token[0] == '#'
          comments << token.gsub(/# */, '')
        else
          magic_number = token
        end
      end

      raise "Unknown magic number"  unless token_number[magic_number]

      while tokens.size < token_number[magic_number]
        content.gsub!(/\A[ \t\r\n]+/, '')
        token = get_next_token!(content)
        if token[0] == '#'
          comments << token.gsub(/# */, '')
        else
          tokens << token
        end
      end

      width, height, maxgray = tokens

      result = {
        :magic_number => magic_number,
        :width        => width,
        :height       => height,
        :data         => content
      }
      result[:maxgray]  = maxgray   if maxgray
      result[:comments] = comments  unless comments.empty?

      result
    end

    def self.token_number  # :nodoc:
      {
        'P1' => 2,
        'P2' => 3,
        'P3' => 3,
        'P4' => 2,
        'P5' => 3,
        'P6' => 3
      }
    end

    def self.get_next_token!(content)  # :nodoc:
      if content[0] == '#'
        token, rest = content.split("\n", 2)
      else
        token, rest = content.split(/[ \t\r\n]|(?=#)/, 2)
      end
      content.clear << rest

      token
    end
  end
end
