# frozen_string_literal: true

module PNM

  # Base class for all PNM exceptions.
  class Error < StandardError; end

  class ArgumentError < Error; end
  class ParserError   < Error; end
  class DataSizeError < Error; end
  class DataError     < Error; end
end
