#!/usr/bin/env ruby
# frozen_string_literal: true

require 'redis'

# This class implements a token bucket for rate limiting.
# The "checket" part is for sanity checking.
class FixedWindowCounter
  attr_reader :app, :time_interval, :rate, :redis_key, :redis

  def initialize(app, time_interval:, rate:, redis_key:)
    @app = app
    @time_interval = time_interval
    @rate = rate
    @redis_key = redis_key
    @redis = Redis.new(host: ENV.fetch('REDIS_HOST', 'localhost'), port: ENV.fetch('REDIS_PORT', 6380))
  end

  def call(env)
    if allow_request?
      @app.call(env)
    else
      [429, { 'Content-Type' => 'text/plain' }, ['Rate limit exceeded']]
    end
  end

  # This method checks if a request is allowed with
  # respect to a fixed window counter rate limiter.
  def allow_request?
    # Get the current timestamp
    # current_time = Time.now.to_i

    # Get the current count and timestamp from Redis
    count = redis.get("#{redis_key}:count").to_i
    timestamp = redis.get("#{redis_key}:timestamp").to_i

    # If the timestamp is older than the current time interval,
    # reset the count and timestamp
    if current_time - timestamp > time_interval
      count = 0
      timestamp = current_time
    end

    # If the count is less than the rate, allow the request
    if count < rate
      redis.set("#{redis_key}:count", count + 1)
      redis.set("#{redis_key}:timestamp", timestamp)
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
  # checker = FixedWindowCounter.new(bucket_size: 10, refill_rate: 1, redis_key: 'my_rate_limit')
  # # Example invocations
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"

  # checker = FixedWindowCounter.new(bucket_size: 1, refill_rate: 1, redis_key: 'new_rate_limit')
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(0.5)
  # puts "Request allowed? #{checker.allow_request?}"
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(1)
  # puts "Request allowed? #{checker.allow_request?}"
end
