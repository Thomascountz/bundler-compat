module Bundler
  module Compat
    module Reporters
      class BaseReporter
        def initialize(results, target_version:)
          @results = results
          @target_version = target_version
        end

        def print(results, output: $stdout)
          raise NotImplementedError, "Subclasses must implement the report method"
        end

        private

        attr_reader :results, :target_version

        def preamble
          <<~REPORT.lines
            Bundle Compatibility Report
            #{"=" * 50}
            Target Rails version: #{target_version}
            Found #{results.conflicts.size} conflicts(s)

          REPORT
        end
      end
    end
  end
end
