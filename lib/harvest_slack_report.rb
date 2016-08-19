# encoding: utf-8
require 'harvested'
require 'httparty'
require 'slack-ruby-client'
require 'active_support/all'
require 'raven/base'

USER_AGENT = "I want a public API: domain #{ENV['HARVEST_DOMAIN']}".freeze

# Posts summary harvest data to a slack channel
class HarvestSlackReport
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

    no_warn_users = [980033, 984890] #(matt & laura)

    people = harvest.users.all.select { |u| u.is_active? && !ignore_users.include?(u.id) }

    # puts people.map{ |u| u.email }

    projects = harvest.projects.all

    # puts projects

    time_off_ids = people_with_scheduled_time_off(from_date)

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
        total_hours = entries.map(&:hours).sum.round(2)

        hours_by_project = entries.group_by(&:project_id).map do |project_id, es|
          proj = projects.find { |pr| pr.id == project_id }

          if proj.code.present?
            title = proj.code
            # If there is a code, then this should be in the timesheet notes
            if es.select { |e| e['notes'] !~ /#{Regexp.escape title}/ }.any?
              title = "#{title} *check timesheet titles*"
            end
          else
            title = proj.name
          end

          { title:  title, value: es.map(&:hours).sum.round(2), short: true }
        end

        color_code =  case total_hours
                      when 0..2
                        '#D0021B'
                      when 2..4
                        '#F59423'
                      when 4..6
                        '#F8C61C'
                      else
                        '#72D321'
                      end

        emoji = case total_hours
                when 0..6
                  ''
                when 6..7
                  ':simple_smile:'
                when 7..8
                  ':+1:'
                else
                  ':military_medal:'
                end

        if time_off_ids.include?(person.id)
          report << { fallback: "#{name} had scheduled time off, but logged #{total_hours} hours: #{harvest_url}",
                      author_name: name,
                      author_link: harvest_url,
                      text: "Logged #{total_hours} hours but, had scheduled time off :palm_tree: :wat:" }
        else
          report << { fallback: "#{name} logged #{total_hours} hours: #{harvest_url}",
                      author_name: name,
                      author_link: harvest_url,
                      text: "Logged #{total_hours} hours #{emoji}",
                      fields: hours_by_project,
                      color: color_code
                    }
        end
      elsif time_off_ids.include?(person.id)
        report << { fallback: "#{name} had scheduled time off",
                    author_name: name,
                    author_link: harvest_url,
                    text: 'had scheduled time off :palm_tree:' }

      else
        report << { fallback: "#{name} logged no time",
                    author_name: name,
                    author_link: harvest_url,
                    text: ':notsureif: Logged no time' } unless no_warn_users.include?(person.id)
      end
      puts "#{i+1}/#{n_people}"
    end

    report
  end

  def self.people_with_scheduled_time_off(from_date=Date.today)
    puts 'fetching people with time off'
    if ENV['FORECAST_TOKEN'] # Bearer Token
      date = from_date.to_date.to_formatted_s(:db)
      assignments = HTTParty.get(
        "https://api.forecastapp.com/assignments?end_date=#{date}&start_date=#{date}&state=active",
        headers: {
          "User-Agent" => USER_AGENT,
          "authorization" => ENV['FORECAST_TOKEN'],
          "forecast-account-id" => ENV['FORECAST_ACCOUNT_ID']
        }
      )

      puts 'assignments'
      puts assignments

      projects = HTTParty.get(
        "https://api.forecastapp.com/projects",
        headers: {
          'User-Agent' => USER_AGENT,
          'authorization' => ENV['FORECAST_TOKEN'],
          'forecast-account-id' => ENV['FORECAST_ACCOUNT_ID']
        }
      )

      puts 'projects'
      puts projects

      people = HTTParty.get(
        "https://api.forecastapp.com/people",
        headers: {
          'User-Agent' => USER_AGENT,
          'authorization' => ENV['FORECAST_TOKEN'],
          'forecast-account-id' => ENV['FORECAST_ACCOUNT_ID']
        }
      )

      puts 'people'
      puts people

      if assignments['reason'] == 'expired-token'
        Raven.capture_exception('Forecase token expired')
        return []
      elsif  assignments['reason'] == 'non-existent-token'
        Raven.capture_exception('Forecase token not set')
        return []
      end

      time_off_id = projects['projects'].select { |pr| pr['name'] == 'Time Off' }[0]['id']
      people_ids = assignments['assignments'].select { |ass| ass['project_id'] == time_off_id }.map{ |a| a['person_id'] }
      people_with_time_off = people['people'].select { |person| people_ids.include?(person['id']) }
      people_with_time_off.map{ |person| person['harvest_user_id'] }
    else
      []
    end
  end

  def self.run
    today = Date.today

    if today.monday? || today.sunday?
      puts 'No need to report over the weekend'
      return unless !!ENV['FORCE']
    end

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
