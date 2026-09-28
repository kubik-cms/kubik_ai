# frozen_string_literal: true

require_relative "lib/kubik_ai/version"

Gem::Specification.new do |spec|
  spec.name          = "kubik_ai"
  spec.version       = KubikAi::VERSION
  spec.authors       = ["Bart Oleszczyk"]
  spec.email         = ["bart@primate.co.uk"]

  spec.summary       = "AI integrations for Kubik CMS"
  spec.description   = "Site context, RubyLLM gateway, and media analysis for Kubik applications"
  spec.homepage      = "https://github.com/kubik-cms/kubik_ai"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    files = `git ls-files -z 2>/dev/null`.split("\x0")
    if files.empty?
      Dir.glob("{app,config,lib}/**/*", File::FNM_DOTMATCH).select { |f| File.file?(f) }
    else
      files.reject { |f| f.match(%r{\A(?:test|spec)/}) }
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "activeadmin", ">= 2.13"
  spec.add_dependency "kubik_interface_elements", ">= 0.2.10"
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "ruby_llm", ">= 1.0"
  spec.add_development_dependency "pg"
end
