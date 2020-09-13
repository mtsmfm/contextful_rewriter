require_relative 'lib/contextful_rewriter/version'

Gem::Specification.new do |spec|
  spec.name          = "contextful_rewriter"
  spec.version       = ContextfulRewriter::VERSION
  spec.authors       = ["Fumiaki MATSUSHIMA"]
  spec.email         = ["mtsmfm@gmail.com"]

  spec.summary       = %q{}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/mtsmfm/contextful_rewriter"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mtsmfm/contextful_rewriter"
  spec.metadata["changelog_uri"] = "https://github.com/mtsmfm/blob/main/contextful_rewriter"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "parser", ">= 2.7.1.4"
  spec.add_development_dependency "pry-byebug", ">= 3.9.0"
end
