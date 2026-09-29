# frozen_string_literal: true

require "test_helper"

class ContextCompilerTest < Minitest::Test
  def setup
    KubikAi.config.clear_context_providers!
    Kubik::AiConfiguration.delete_all
  end

  def test_compile_without_providers_returns_empty
    assert_equal "", KubikAi::Context::Compiler.compile
  end

  def test_compile_includes_scoped_instructions
    Kubik::AiConfiguration.create!(
      singleton_guard: 1,
      enabled: true,
      context_instructions: { "media" => "Use UK English. Mention Loch Ness when relevant." }
    )

    KubikAi.config.register_context_provider :site, KubikAi::Context::Providers::Site

    compiled = KubikAi::Context::Compiler.compile(scopes: [:media])

    assert_includes compiled, "Media library (alt text & tags)"
    assert_includes compiled, "Use UK English"
  end

  def test_compile_omits_instructions_when_scope_not_requested
    Kubik::AiConfiguration.create!(
      singleton_guard: 1,
      enabled: true,
      context_instructions: { "media" => "Should not appear" }
    )

    compiled = KubikAi::Context::Compiler.compile(scopes: [:seo])

    refute_includes compiled, "Should not appear"
  end
end
