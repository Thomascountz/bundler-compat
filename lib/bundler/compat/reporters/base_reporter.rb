module Bundler
  module Compat
    module Reporters
      class BaseReporter
        def initialize(results, target_gem:)
          @results = results
          @target_gem = target_gem
          raise ArgumentError, "target_gem is required" if target_gem.nil?
        end

        def print(results, output: $stdout)
          raise NotImplementedError, "Subclasses must implement the report method"
        end

        private

        attr_reader :results, :target_gem

        def preamble
          <<~REPORT.lines
            Bundle Compatibility Report
            #{"=" * 50}
            Target #{target_gem.name} version: #{target_gem.version}
            Found #{results.conflicts.size} conflicts(s)

          REPORT
        end
      end
    end
  end
end
