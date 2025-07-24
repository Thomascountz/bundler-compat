require_relative "base_reporter"
require "bundler/compat/result"
require "json"

module Bundler
  module Compat
    module Reporters
      class JsonReporter < BaseReporter
        def print(output: $stdout)
          report_data = {
            bundle_compatibility_report: {
              conflicts_count: results.conflicts.size,
              conflicts: format_conflicts
            }
          }

          output.puts JSON.pretty_generate(report_data)
        end

        private

        def format_conflicts
          results.conflicts.map do |conflict|
            {
              direct_dependency: conflict.direct_dependency,
              direct_dependency_version: conflict.direct_dependency_version,
              blocking_dependency: conflict.blocking_dependency,
              blocking_dependency_version: conflict.blocking_dependency_version,
              target_dependency: conflict.target_dependency,
              target_dependency_version: conflict.target_dependency_version,
              target_dependency_requirement: conflict.target_dependency_requirement,
              dependency_chain: conflict.dependency_chain
            }
          end
        end
      end
    end
  end
end