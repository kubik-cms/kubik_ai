# frozen_string_literal: true

require "test_helper"

class ContextCompilerTest < Minitest::Test
  def test_compile_without_providers_returns_empty
    KubikAi.config.clear_context_providers!

    assert_equal "", KubikAi::Context::Compiler.compile
  end
end
