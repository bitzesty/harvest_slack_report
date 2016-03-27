require 'harvest_slack_report/version'
require 'harvested'
require 'slack-ruby-client'
require 'active_support/all'

# Posts summary harvest data to a slack channel
module HarvestSlackReport
  def self.fetch_harvest_data
    domain = ENV.fetch 'HARVEST_DOMAIN'
    username = ENV.fetch 'HARVEST_USERNAME'
    password = ENV.fetch 'HARVEST_PASSWORD'
    puts "Collecting Harvest data for #{domain}..."
    harvest = Harvest.hardy_client(subdomain: domain,
                                   username: username,
                                   password: password
                                  )

    people = harvest.users.all.select { |u| u.is_active? }

    # puts people.map{ |u| u.email }

    projects = harvest.projects.all

    # puts projects

    puts 'Aggregating data...'

    report = {}
    n_people = people.count
    people.each_with_index do |person, i|
      # TODO Make this customisable
      # Timesheet entries for yesterday
      entries = harvest.reports.time_by_user(person.id, Time.now - 2.days, Time.now)

      name = "#{person.first_name} #{person.last_name}"

      if entries
        total_hours = entries.map { |x| x.hours }.sum

        hours_by_project = entries.group_by { |x| x.project_id }.map do |project_id, es|
          proj = projects.find { |pr| pr.id == project_id }
          { project: proj.name, code: proj.code, hours: es.map { |h| h.hours }.sum }
        end

        report[name] = { id: person.id, hours: total_hours.round(2), projects: hours_by_project }
      else
        report[name] = { id: person.id, hours: 0 }
      end
      puts "#{i+1}/#{n_people}"
    end

    report
  end

  def self.run
    report = fetch_harvest_data
    # {"Cat Bliss"=>{:id=>1033651, :hours=>0.0, :projects=>[]}, "Craig Priestman"=>{:id=>1160616, :hours=>0.0, :projects=>[]}, "Emiliano Ritiro"=>{:id=>1004801, :hours=>1.83, :projects=>[{:project=>"E-Voucher", :code=>"", :hours=>1.83}]}, "Hildebrando Rueda"=>{:id=>1208497, :hours=>0.0, :projects=>[]}, "Kate Aalcraft"=>{:id=>1078381, :hours=>0.0, :projects=>[]}, "Laura Paplauskaite"=>{:id=>984890, :hours=>0.0, :projects=>[]}, "Mario Andres Correa"=>{:id=>1004802, :hours=>6.4, :projects=>[{:project=>"Internal", :code=>"", :hours=>0.62}, {:project=>"QAVS Support June 2015-2016", :code=>"", :hours=>5.779999999999999}]}, "Matthew Ford"=>{:id=>980033, :hours=>0.38, :projects=>[{:project=>"QAVS Support June 2015-2016", :code=>"", :hours=>0.38}]}, "Mauricio Cinelli"=>{:id=>1004804, :hours=>7.1, :projects=>[{:project=>"Internal", :code=>"", :hours=>4.38}, {:project=>"E-Voucher", :code=>"", :hours=>2.7199999999999998}]}, "Nadejda Karkeleva"=>{:id=>1217385, :hours=>0.0, :projects=>[]}, "Ruslan Khamidullin"=>{:id=>1004806, :hours=>2.7, :projects=>[{:project=>"QAE Support April 2015-2016", :code=>"", :hours=>2.7}]}, "Vasili Kachalko"=>{:id=>1000701, :hours=>6.5, :projects=>[{:project=>"Lupin Support March 2016", :code=>"LUPIN0316", :hours=>6.5}]}}
    # puts report.inspect


    if ENV['SLACK_API_TOKEN'].present?
      puts 'Posting to Slack'
      Slack.configure do |config|
        config.token = ENV['SLACK_API_TOKEN']
      end

    end
  end
end
