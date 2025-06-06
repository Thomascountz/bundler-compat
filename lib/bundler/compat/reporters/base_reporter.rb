module Bundler
  module Compat
    module Reporters
      class BaseReporter
        def initialize(results)
          @results = results
        end

        def print(results, output: $stdout)
          raise NotImplementedError, "Subclasses must implement the report method"
        end

        private

        attr_reader :results

        def preamble
          <<~REPORT.lines
            Bundle Compatibility Report
            #{"=" * 50}
            Found #{results.conflicts.size} conflicts(s)

          REPORT
        end
      end
    end
  end
end
