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
    @app.call(env)

    # if allow_request?
    #   @app.call(env)
    # else
    #   [429, { 'Content-Type' => 'text/plain' }, ['Rate limit exceeded']]
    # end
  end

  # TODO: define an elapsed_time method
  # def elapsed_time
  #   timestamp = redis.get("#{redis_key}:timestamp").to_i
  #   current_time - timestamp
  # end

  def allow_request?
    true
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
