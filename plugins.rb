# frozen_string_literal: true

require "bundler/compat"
require "optparse"

class BundlerCompatPlugin < Bundler::Plugin::API
  command "compat"

  def exec(command, args)
    opts = parse_args(args)

    target_version = opts[:target_version] || "8.1.0"
    format = opts[:format] || "plain"

    begin
      conflict_finder = Bundler::Compat::ConflictFinder.new(target_version: target_version)
      results = conflict_finder.search

      reporter = case format
      when "json"
        Bundler::Compat::Reporters::JsonReporter.new(results, target_version: target_version)
      when "plain"
        Bundler::Compat::Reporters::TextReporter.new(results, target_version: target_version)
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
      opts.banner = "Usage: bundle compat [target_version] [options]"

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

    # First remaining argument is the target version if provided
    options[:target_version] = args_copy.first if args_copy.any?

    options
  rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => e
    Bundler.ui.error "Error: #{e.message}"
    Bundler.ui.error "Run 'bundle compat --help' for usage information."
    exit 1
  end
end
