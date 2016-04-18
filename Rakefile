require "rspec/core/rake_task"
require './lib/harvest_slack_report'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require 'dotenv/tasks'

task :people_with_scheduled_time_off => :dotenv do
  HarvestSlackReport.people_with_scheduled_time_off
end
