# bundler-compat

A Ruby gem that provides tools to find and report dependency conflicts in Ruby projects using Bundler. Specifically focuses on identifying conflicts with Rails components when upgrading to newer versions.

## Installation

### As a Bundler Plugin

For local development or testing:

```bash
bundle plugin install --path '/path/to/repo/bundler-compat' bundler-compat
```

For unreleased versions from Git:

```bash
bundle plugin install --git 'https://github.com/thomascountz/bundler-compat' --branch "main" bundler-compat
```


## Usage

### As a Bundler Plugin

Check compatibility against default Rails version (8.1.0):
```bash
bundle compat
```

Check against a specific Rails version:
```bash
bundle compat 7.0.0
```

Output results in JSON format:
```bash
bundle compat --format json
bundle compat 7.0.0 --format json
```

Show help:
```bash
bundle compat --help
```

The plugin exits with status code 1 if conflicts are found.

### As a Library

```ruby
require 'bundler/compat'

# Read your Gemfile.lock
lockfile_contents = File.read('Gemfile.lock')

# Find conflicts for Rails 7.0.0
finder = Bundler::Compat::ConflictFinder.new(lockfile_contents, '7.0.0')
results = finder.search

# Output results
reporter = Bundler::Compat::Reporters::TextReporter.new
reporter.report(results)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Commands

```bash
# Setup development environment
bin/setup

# Run tests
rake test

# Run linter (Standard Ruby)
rake standard

# Run both tests and linter (default task)
rake

# Interactive console
bin/console

# Install gem locally
bundle exec rake install

# Release new version
bundle exec rake release
```

## Requirements

- Ruby 3.1+
- Bundler

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

