require "sinatra"
require "rack-timeout"
require "redis"
require "logger"
require "oj"

class Repository
  def initialize(redis)
    @redis = redis
  end

  def save(id, params)
    @redis.set(key(id), Oj.dump(params))
  end

  def fetch(id)
    @redis.get(key(id))
  end

  protected

  def key(id)
    "charboost:#{id}"
  end
end

use Rack::Timeout

enable :logging

configure :development, :production do
  ENV["REDISTOGO_URL"] = 'redis://localhost:6379' unless ENV["REDISTOGO_URL"]
  redis = Redis.new(url: ENV["REDISTOGO_URL"], driver: :hiredis, logger: Logger.new($stdout))
  set :repository, Repository.new(redis)
end

get "/notify" do
  id = params["ifa"] || params["uuid"]
  settings.repository.save(id, params) if id
  200
end

get "/fetch" do
  log = settings.repository.fetch(params[:id]) if params[:id]
  if log
    [200, {"Content-Type" => "application/json"}, [log]]
  else
    404
  end
end