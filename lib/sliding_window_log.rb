#!/usr/bin/env ruby
# frozen_string_literal: true

require 'redis'

# Yet another rate limiter.
class SlidingWindowLog
  attr_reader :app, :time_interval, :rate, :redis_key, :redis

  # FIXME: adjust parameters appropriately
  def initialize(app, time_interval:, rate:, redis_key:)
    @app = app
    @time_interval = time_interval
    @rate = rate
    @redis_key = redis_key
    @redis = Redis.new(host: ENV.fetch('REDIS_HOST', 'localhost'), port: ENV.fetch('REDIS_PORT', 6380))
  end

  def call(env)
    if allow_request?
      app.call(env)
    else
      [429, { 'Content-Type' => 'text/plain' }, ['Rate limit exceeded']]
    end
  end

  def allow_request?
    # remove outdated timestamps
    min_score = current_time - time_interval
    redis.zremrangebyscore(redis_key, 0, min_score)

    # count the number of requests
    count = redis.zcard(redis_key)
    if count < rate
      redis.zadd(redis_key, current_time, current_time)
      return true
    end

    false
  end

  private

  def current_time
    Time.now.to_i
  end
end

if __FILE__ == $PROGRAM_NAME
  # checker = SlidingWindowLog.new(bucket_size: 10, refill_rate: 1, redis_key: 'my_rate_limit')
  # # Example invocations
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"

  # checker = SlidingWindowLog.new(bucket_size: 1, refill_rate: 1, redis_key: 'new_rate_limit')
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(0.5)
  # puts "Request allowed? #{checker.allow_request?}"
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(1)
  # puts "Request allowed? #{checker.allow_request?}"
end
