require_relative "base_reporter"
require "bundler/compat/result"

module Bundler
  module Compat
    module Reporters
      class TextReporter < BaseReporter
        def print(output: $stdout)
          output.puts preamble

          conflicts = results.conflicts

          if conflicts.any?
            report = []

            conflicts.group_by(&:direct_dependency).each do |direct_dep, direct_dep_conflicts|
              report << "#{direct_dep}:"

              direct_dep_conflicts.each do |conflict|
                report << "  └─ #{conflict.blocking_dependency} (#{conflict.blocking_dependency_version})"
                report << "     requires #{conflict.target_dependency} #{conflict.target_dependency_requirement}"
                report << "     dependency_chain: #{conflict.dependency_chain}" if conflict.dependency_chain && !conflict.dependency_chain.empty?
                report << ""
              end
            end

            output.puts report.join("\n")
          end
        end
      end
    end
  end
end
