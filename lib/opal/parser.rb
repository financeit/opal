# frozen_string_literal: true

require 'opal/ast/builder'
require 'opal/rewriter'
require 'opal/parser/patch'

module Opal
  module Source
    class Buffer < Parser::Source::Buffer
      def self.recognize_encoding(string)
        super || Encoding::UTF_8
      end
    end
  end

  class Parser < ::Parser::Ruby25
    class << self
      attr_accessor :diagnostics_consumer

      def default_parser
        parser = super

        parser.diagnostics.all_errors_are_fatal = true
        parser.diagnostics.ignore_warnings      = false

        parser.diagnostics.consumer =
          if RUBY_ENGINE == 'opal'
            ->(diag) {}
          else
            diagnostics_consumer
          end

        parser
      end
    end

    self.diagnostics_consumer = ->(diagnostic) { $stderr.puts(diagnostic.render) }

    def initialize(*)
      super(Opal::AST::Builder.new)
    end

    def parse(source_buffer)
      parsed = super
      rewriten = rewrite(parsed)
      rewriten
    end

    def rewrite(node)
      Opal::Rewriter.new(node).process
    end
  end
end
