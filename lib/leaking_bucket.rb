#!/usr/bin/env ruby
# frozen_string_literal: true

require 'redis'

# This class implements a leaking bucket for rate limiting.
class LeakingBucket
  attr_reader :app, :bucket_size, :leak_rate, :redis

  def initialize(app, bucket_size:, leak_rate:)
    @app = app
    @bucket_size = bucket_size
    @leak_rate = leak_rate # Leakings added per second
    @redis = Redis.new(host: ENV.fetch('REDIS_HOST', 'localhost'), port: ENV.fetch('REDIS_PORT', 6380))
  end

  def call(env)
    request = Rack::Request.new(env)
    redis_key = request.params['redis_key'] || 'default_rate_limit'

    initialize_bucket(redis_key) unless bucket_initialized?(redis_key)

    if allow_request?(redis_key)
      @app.call(env)
    else
      [429, { 'Content-Type' => 'text/plain' }, ['Rate limit exceeded']]
    end
  end

  def allow_request?(redis_key)
    current_count = redis.get("#{redis_key}:request_count").to_i
    elapsed_time = current_time - redis.get("#{redis_key}:timestamp").to_f
    leaked_count = (elapsed_time * leak_rate).floor
    adjusted_count = [current_count - leaked_count, 0].max

    if adjusted_count < bucket_size
      update_bucket(redis_key, adjusted_count + 1)
      true
    else
      false
    end
  end

  private

  # TODO: hook this up.
  def calculate_leaked_count(elapsed_time)
    (elapsed_time * @leak_rate).floor
  end

  def update_bucket(redis_key, new_count)
    redis.multi do |r|
      r.set("#{redis_key}:request_count", new_count)
      r.set("#{redis_key}:timestamp", current_time)
    end
  end

  def bucket_initialized?(redis_key)
    redis.exists("#{redis_key}:request_count") && redis.exists("#{redis_key}:timestamp")
  end

  def initialize_bucket(redis_key)
    redis.multi do |r|
      r.setnx("#{redis_key}:request_count", 0)
      r.setnx("#{redis_key}:timestamp", current_time)
    end
  end

  def current_time
    Time.now.to_f
  end
end

# Step 2: Make it self-executable and provide example usage
if __FILE__ == $PROGRAM_NAME
  # checker = LeakingBucket.new(bucket_size: 10, leak_rate: 1, redis_key: 'my_rate_limit')

  # # Example invocations
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"

  checker = LeakingBucket.new(bucket_size: 1, leak_rate: 1, redis_key: 'new_rate_limit')
  puts "Request allowed? #{checker.allow_request?}"
  sleep(0.5)
  puts "Request allowed? #{checker.allow_request?}"
  puts "Request allowed? #{checker.allow_request?}"
  sleep(1)
  puts "Request allowed? #{checker.allow_request?}"
end
