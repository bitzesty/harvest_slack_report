require 'sinatra'

class HarvestApp < Sinatra::Base
  use Rack::Auth::Basic, 'Nope' do |username, password|
    username == ENV.fetch('AUTH_USER') && password == ENV.fetch('AUTH_PASSWORD')
  end

  get '/' do
    'OK'
  end
end
