require 'sinatra'

class HarvestApp < Sinatra::Base
  get '/' do
    'OK'
  end
end
