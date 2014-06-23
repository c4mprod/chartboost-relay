require "sinatra"
require "rack-timeout"
require "redis"
require "logger"
require "oj"
require "repository"

enable :logging

configure :development, :production do
  use Rack::Timeout

  ENV["REDISTOGO_URL"] = "redis://localhost:6379" unless ENV["REDISTOGO_URL"]
  redis = Redis.new(url: ENV["REDISTOGO_URL"], driver: :hiredis, logger: Logger.new($stdout))
  set :repository, Repository.new(redis)
end

get "/notify" do
  settings.repository.save(params)
  200
end

get "/fetch" do
  logs = settings.repository.fetch(params)
  [200, {"Content-Type" => "application/json"}, ["[#{logs.join(',')}]"]]
end

get "/all" do
  logs = settings.repository.all
  [200, {"Content-Type" => "application/json"}, ["[#{logs.join(',')}]"]]
end

delete "/all" do
  settings.repository.reset
end