require 'harvest_slack_report/version'
require 'harvested'
require 'slack-ruby-client'
require 'active_support/all'

# Posts summary harvest data to a slack channel
module HarvestSlackReport
  def self.run
    puts 'Collecting Harvest data ...'
    harvest = Harvest.hardy_client(subdomain: ENV['HARVEST_DOMAIN'], username: ENV['HARVEST_USERNAME'], password: ENV['HARVEST_PASSWORD'])

    people = harvest.users.all.select { |u| u.is_active? }
    # puts people.inspect
    puts 'Aggregating data'

    report = {}
    people.each do |person|
      # get timesheet entries for yesterday
      entries = harvest.reports.time_by_user(person.id, Time.now - 1.day, Time.now)
      if entries
        hours = entries.map { |x| x.hours }.sum
        report[person.id] = { name: "#{person.first_name} #{person.last_name}", hours: hours.round(2) }
        # puts entries.inspect
      end
    end

    puts report.inspect

    puts 'Posting to Slack'
  end
end
