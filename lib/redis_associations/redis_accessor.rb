module RedisAccessor
  EMPTY_SET_KEY = "asdfghjqwertyuasdzxcxcvcvxcd"

  @@redis = nil
  def redis
    if @@redis.present?
      return @@redis
    end
    @@redis = Redis.new
  end
end
