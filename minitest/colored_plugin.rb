# frozen_string_literal: true

module Minitest
  def self.plugin_colored_init(options)
    io = options.fetch(:io, $stdout)
    self.reporter.reporters << SimpleColors.new(io)
    self.reporter.reporters.reject! { it.is_a? ProgressReporter }
  end

  class SimpleColors < Minitest::AbstractReporter
    ESC    = "\e["
    RESET    = "#{ESC}0m"
    GREEN  = "#{ESC}32m"
    RED    = "#{ESC}31m"
    YELLOW = "#{ESC}33m"
    COLORS_MAP_BY_RESULT_SYMBOL = Hash.new(RESET).merge({
      "." => GREEN,
      "E" => RED,
      "F" => RED,
      "S" => YELLOW
    }).freeze
    RESULT_CODES = {
      "." => "P"
    }

    attr_reader :io
    def initialize(io)
      @io = io
    end

    def record(result)
      buf = "#{COLORS_MAP_BY_RESULT_SYMBOL[result.result_code]}" \
            "#{RESULT_CODES[result.result_code] || result.result_code}" \
            "#{RESET}"

      io.print(buf)
    end
  end
end

