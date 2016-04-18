require 'sinatra'
require './lib/seal'
require './lib/github_fetcher'
require './lib/message_builder'
require './lib/slack_poster'

class HarvestApp < Sinatra::Base

  get '/' do
    "OK"
  end

end
