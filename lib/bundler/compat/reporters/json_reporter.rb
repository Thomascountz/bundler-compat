require_relative "base_reporter"
require "bundler/compat/result"
require "json"

module Bundler
  module Compat
    module Reporters
      class JsonReporter < BaseReporter
        def print(output: $stdout)
          report_data = {
            target_gem: target_gem.name,
            target_version: target_gem.version.to_s,
            target_components: target_gem.components? ? target_gem.target_gems.to_a.sort : nil,
            conflicts_count: results.conflicts.size,
            conflicts: format_conflicts_hierarchical
          }.compact

          output.puts JSON.pretty_generate(report_data)
        end

        private

        def format_conflicts_hierarchical
          results.conflicts.group_by(&:direct_dependency).map do |direct_dep, direct_dep_conflicts|
            {
              direct_dependency: direct_dep,
              direct_dependency_version: direct_dep_conflicts.first.direct_dependency_version,
              blocking_dependencies: direct_dep_conflicts.map do |conflict|
                {
                  blocking_dependency: conflict.blocking_dependency,
                  blocking_dependency_version: conflict.blocking_dependency_version,
                  target_dependency: conflict.target_dependency,
                  target_dependency_version: conflict.target_dependency_version,
                  target_dependency_requirement: conflict.target_dependency_requirement,
                  dependency_chain: conflict.dependency_chain
                }
              end
            }
          end
        end
      end
    end
  end
end
