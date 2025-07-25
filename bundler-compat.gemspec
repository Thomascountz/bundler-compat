# frozen_string_literal: true

require_relative "lib/bundler/compat/version"

Gem::Specification.new do |spec|
  spec.name = "bundler-compat"
  spec.version = Bundler::Compat::VERSION
  spec.authors = ["Thomas Countz"]
  spec.email = ["thomascountz@gmail.com"]

  spec.summary = "Bundler plugin for identifying dependency conflicts in Ruby projects."
  spec.description = "This gem provides tools to find and report dependency conflicts in Ruby projects using Bundler. Can be used as a library or installed as a bundler plugin."
  spec.homepage = "https://github.com/thomascountz/bundler-compat"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/thomascountz/bundler-compat/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "bundler", "~> 2.0"
end
