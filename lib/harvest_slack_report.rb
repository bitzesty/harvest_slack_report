# encoding: utf-8

require_relative 'harvest_slack_report/version'
require 'harvested'
require 'slack-ruby-client'
require 'active_support/all'

# Posts summary harvest data to a slack channel
module HarvestSlackReport
  def self.fetch_harvest_data(from_date)
    domain = ENV.fetch 'HARVEST_DOMAIN'
    username = ENV.fetch 'HARVEST_USERNAME'
    password = ENV.fetch 'HARVEST_PASSWORD'
    puts "Collecting Harvest data for #{domain}..."
    harvest = Harvest.hardy_client(subdomain: domain,
                                   username: username,
                                   password: password
                                  )

    ignore_users = if ENV['IGNORE_USERS'].present?
      ENV['IGNORE_USERS'].split(',').map{ |user_id| user_id.to_i }
    else
      []
    end

    people = harvest.users.all.select { |u| u.is_active? && !ignore_users.include?(u.id) }

    # puts people.map{ |u| u.email }

    projects = harvest.projects.all

    # puts projects

    puts 'Aggregating data...'

    report = []
    n_people = people.count
    people.each_with_index do |person, i|
      # TODO Make this customisable
      # Timesheet entries for yesterday
      entries = harvest.reports.time_by_user(person.id, from_date, Time.now)

      name = "#{person.first_name} #{person.last_name}"

      harvest_url = "https://#{domain}.harvestapp.com/time/day/#{from_date.strftime("%Y/%m/%d")}/#{person.id}"

      if entries && entries.any?
        total_hours = entries.map { |x| x.hours }.sum.round(2)

        hours_by_project = entries.group_by { |x| x.project_id }.map do |project_id, es|
          proj = projects.find { |pr| pr.id == project_id }
          title = proj.code.present? ? proj.code : proj.name
          { title:  title, value: es.map { |h| h.hours }.sum.round(2), short: true }
        end

        color_code = case total_hours
        when 0..2
          "#D0021B"
        when 2..4
          "#F59423"
        when 4..5
          "#F8C61C"
        else
          "#72D321"
        end

        emoji = case total_hours
        when 0..6
          ""
        when 6..7
          ":simple_smile:"
        when 7..8
          ":+1:"
        else
          ":military_medal:"
        end

        report << { fallback: "#{name} logged #{total_hours} hours",
                    text: "<#{harvest_url}|#{name}> logged #{total_hours} hours #{emoji}",
                    fields: hours_by_project,
                    color: color_code
                  }

      else
        report << { fallback: "#{name} logged no time", text: "<#{harvest_url}|#{name}> logged no time :notsureif:" }
      end
      puts "#{i+1}/#{n_people}"
    end

    report
  end

  def self.run
    from_date = Time.now - 24.hours
    report = fetch_harvest_data(from_date)

    if ENV['SLACK_API_TOKEN'].present?
      puts 'Posting to Slack'
      Slack.configure do |config|
        config.token = ENV['SLACK_API_TOKEN']
      end
      client = Slack::Web::Client.new
      client.auth_test
      client.chat_postMessage(channel: '#2-standup',
                              text: "Time Report from #{from_date.to_formatted_s(:rfc822)} to now:",
                              attachments: report,
                              as_user: true
                             )
    else
      puts 'SLACK_API_TOKEN needs to be set'
      puts report.inspect
    end
  end
end
