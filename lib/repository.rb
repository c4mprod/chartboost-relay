class Repository
  def initialize(redis)
    @redis = redis
  end

  def save(params)
    ifa = params["ifa"]
    uuid = params["uuid"]
    id = unique_id!
    @redis.pipelined do
      @redis.set(log_key(id), Oj.dump(params))
      @redis.sadd(ifa_key(ifa), id) if ifa
      @redis.sadd(uuid_key(uuid), id) if uuid
    end
  end

  def fetch(params)
    case
      when params["ifa"]
        all(ifa_key(params["ifa"]))
      when params["uuid"]
        all(uuid_key(params["uuid"]))
      else
        []
    end
  end

  def all(from=all_key)
    @redis.sort(from, by: :nosort, get: log_key("*"))
  end

  def reset
    @redis.flushdb
  end

  protected

  def unique_id!
    id = @redis.incr(last_id_key)
    @redis.sadd(all_key, id)
    id
  end

  def last_id_key
    "chartboost:last_id"
  end

  def all_key
    "chartboost:all"
  end

  def ifa_key(ifa)
    "chartboost:ifa:#{ifa}"
  end

  def uuid_key(uuid)
    "chartboost:uuid:#{uuid}"
  end

  def log_key(id)
    "chartboost:log:#{id}"
  end
end