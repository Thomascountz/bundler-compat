# frozen_string_literal: true

require "bundler/compat"
require "optparse"

class BundlerCompatPlugin < Bundler::Plugin::API
  command "compat"

  def exec(command, args)
    opts = parse_args(args)

    # Create target gem specification
    unless opts[:gem_name] && opts[:target_version]
      Bundler.ui.error "Error: Both gem name and version are required. Run 'bundle compat --help' for usage information."
      exit 1
    end

    target_gem = Bundler::Compat::TargetGem.new(
      name: opts[:gem_name],
      version: opts[:target_version]
    )

    format = opts[:format] || "plain"

    begin
      conflict_finder = Bundler::Compat::ConflictFinder.new(target_gem: target_gem)
      results = conflict_finder.search

      reporter = case format
      when "json"
        Bundler::Compat::Reporters::JsonReporter.new(results, target_gem: target_gem)
      when "plain"
        Bundler::Compat::Reporters::TextReporter.new(results, target_gem: target_gem)
      else
        Bundler.ui.error "Invalid format: #{format}. Use 'json' or 'plain'."
        exit 1
      end

      reporter.print

      if results.conflicts.any?
        exit 1
      end
    rescue => e
      Bundler.ui.error "Error running compat check: #{e.message}"
      e.backtrace.each { |line| Bundler.ui.error line }
      exit 1
    end
  end

  private

  def parse_args(args)
    options = {}
    args_copy = args.dup

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: bundle compat [gem_name] [version] [options]"
      opts.separator ""
      opts.separator "Examples:"
      opts.separator "  bundle compat rails 8.1.0       # Check Rails 8.1.0 compatibility"
      opts.separator "  bundle compat rails 7.0.0       # Check Rails 7.0.0 compatibility"
      opts.separator "  bundle compat rspec 4.0.0       # Check RSpec 4.0.0 compatibility"
      opts.separator "  bundle compat devise 5.0.0      # Check Devise 5.0.0 compatibility"
      opts.separator ""
      opts.separator "Options:"

      opts.on("-f", "--format FORMAT", ["json", "plain"],
        "Output format (json, plain)") do |format|
        options[:format] = format
      end


      opts.on("-h", "--help", "Show this help") do
        Bundler.ui.info opts
        exit 0
      end
    end

    # Parse options, leaving remaining arguments in args_copy
    parser.parse!(args_copy)

    # Parse positional arguments - require gem name and version
    case args_copy.length
    when 0
      Bundler.ui.error "Error: Gem name and version are required. Run 'bundle compat --help' for usage information."
      exit 1
    when 1
      Bundler.ui.error "Error: Both gem name and version are required. Usage: bundle compat <gem_name> <version>"
      exit 1
    when 2
      options[:gem_name] = args_copy[0]
      options[:target_version] = args_copy[1]
    else
      Bundler.ui.error "Error: Too many arguments. Run 'bundle compat --help' for usage information."
      exit 1
    end

    options
  rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => e
    Bundler.ui.error "Error: #{e.message}"
    Bundler.ui.error "Run 'bundle compat --help' for usage information."
    exit 1
  end
end
