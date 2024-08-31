#!/usr/bin/env ruby
# frozen_string_literal: true

require 'redis'

# This class implements a token bucket for rate limiting.
# The "checket" part is for sanity checking.
class LeakingBucket
  attr_reader :app, :bucket_size, :leak_rate, :redis, :redis_key

  def initialize(app, bucket_size:, leak_rate:, redis_key:)
    @app = app
    @bucket_size = bucket_size
    @leak_rate = leak_rate # Leakings added per second
    @redis_key = redis_key
    @redis = Redis.new(host: ENV.fetch('REDIS_HOST', 'localhost'), port: ENV.fetch('REDIS_PORT', 6380))

    initialize_bucket
  end

  def call(env)
    if allow_request?
      @app.call(env)
    else
      [429, { 'Content-Type' => 'text/plain' }, ['Rate limit exceeded']]
    end
  end

  def allow_request?
    current_count = redis.get("#{redis_key}:request_count").to_i
    puts "CC: #{current_count}"

    elapsed_time = current_time - redis.get("#{redis_key}:timestamp").to_f
    leaked_count = (elapsed_time * leak_rate).floor

    puts "CT: #{current_time}, ET: #{elapsed_time}, LC: #{leaked_count}, CC: #{current_count}, RC: #{redis.get("#{redis_key}:request_count")}"

    adjusted_count = [current_count - leaked_count, 0].max

    # binding.irb if current_count == 5

    if adjusted_count < bucket_size
      redis.set("#{redis_key}:request_count", current_count + 1)
      redis.set("#{redis_key}:timestamp", current_time)
      true
    else
      false
    end
  end

  private

  def initialize_bucket
    # Start with an empty bucket if not already set
    @redis.setnx("#{redis_key}:request_count", 0)
    @redis.setnx("#{redis_key}:timestamp", current_time)
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
