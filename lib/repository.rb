class Repository
  def initialize(redis)
    @redis = redis
  end

  def save(id, params)
    @redis.pipelined do
      @redis.set(key(id), Oj.dump(params))
      @redis.sadd(key("all"), id)
    end
  end

  def fetch(id)
    @redis.get(key(id))
  end

  def all
    @redis.sort(key("all"), get: "chartboost:*")
  end

  def reset
    @redis.flushdb
  end

  protected

  def key(id)
    "chartboost:#{id}"
  end
end