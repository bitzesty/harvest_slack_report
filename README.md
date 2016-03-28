# HarvestSlackReport

Reporting on daily harvest activity.

## Installation

    $ gem install harvest_slack_report

## Usage

The following environment variables must be set:

    HARVEST_DOMAIN=your subdomain
    HARVEST_USERNAME=your email
    HARVEST_PASSWORD=password
    SLACK_API_TOKEN=slack bot token

    $ harvest_slack_report

[![Deploy](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy)

Set Heroku scheduler with this command: `bundle exec ./exe/harvest_slack_report`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bitzesty/harvest_slack_report. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
