# frozen_string_literal: true

require "bundler/compat"

class BundlerCompatPlugin < Bundler::Plugin::API
  command "compat"

  def exec(command, args)
    target_version = args.first || "8.1.0"

    begin
      conflict_finder = Bundler::Compat::ConflictFinder.new(target_version: target_version)
      results = conflict_finder.search

      reporter = Bundler::Compat::Reporters::JsonReporter.new(results)
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
end
