module PNM

  # Parser for PNM image files. Only for internal usage.
  class Parser

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
      tokens   = []
      comments = []

      until magic_number
        token = next_token!(content)

        if token.start_with?('#')
          comments << token.gsub(/# */, '')
        else
          magic_number = token
        end
      end

      raise "Unknown magic number"  unless token_number[magic_number]

      while tokens.size < token_number[magic_number]
        content.gsub!(/\A[ \t\r\n]+/, '')
        token = next_token!(content)

        if token.start_with?('#')
          comments << token.gsub(/# */, '')
        else
          tokens << token
        end
      end

      width, height, maxgray = tokens

      result = {
        :magic_number => magic_number,
        :width        => width.to_i,
        :height       => height.to_i,
        :data         => content
      }
      result[:maxgray]  = maxgray.to_i  if maxgray
      result[:comments] = comments      unless comments.empty?

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

    def self.next_token!(content)  # :nodoc:
      delimiter = if content.start_with?('#')
                    "\n"
                  else
                    %r{[ \t\r\n]|(?=#)}
                  end

      token, rest = content.split(delimiter, 2)
      content.replace(rest)

      token
    end
  end
end
