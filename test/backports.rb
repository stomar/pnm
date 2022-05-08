# frozen_string_literal: true

module PNM
  module Backports  # :nodoc:
    module Minitest  # :nodoc:

      # Provides workaround for missing value wrappers in minitest < 5.6.0.
      def _(value = nil, &block)
        block || value
      end
    end
  end
end


if Gem.loaded_specs["minitest"].version < Gem::Version.new("5.6.0")
  warn "Using workaround for missing value wrappers in minitest < 5.6.0."
  MiniTest::Spec.send(:include, PNM::Backports::Minitest)
end
