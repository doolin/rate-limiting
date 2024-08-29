#!/usr/bin/env ruby
# frozen_string_literal: true

require 'redis'

# This class implements a token bucket for rate limiting.
# The "checket" part is for sanity checking.
class LeakingBucket
  attr_reader :app, :bucket_size, :refill_rate, :redis_key

  def initialize(app, bucket_size:, refill_rate:, redis_key:)
    @app = app
    @bucket_size = bucket_size
    @refill_rate = refill_rate # Leakings added per second
    @redis_key = redis_key
    @redis = Redis.new(host: ENV.fetch('REDIS_HOST', 'localhost'), port: ENV.fetch('REDIS_PORT', 6380))

    # initialize_bucket
  end

  def call(env)
    if allow_request?
      @app.call(env)
    else
      [429, { 'Content-Type' => 'text/plain' }, ['Rate limit exceeded']]
    end
  end

  def allow_request?
    true
  end

  private

  def initialize_bucket
  end

  def current_time
    Time.now.to_f
  end
end

# Step 2: Make it self-executable and provide example usage
if __FILE__ == $PROGRAM_NAME
  # checker = LeakingBucket.new(bucket_size: 10, refill_rate: 1, redis_key: 'my_rate_limit')

  # # Example invocations
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"

  checker = LeakingBucket.new(bucket_size: 1, refill_rate: 1, redis_key: 'new_rate_limit')
  puts "Request allowed? #{checker.allow_request?}"
  sleep(0.5)
  puts "Request allowed? #{checker.allow_request?}"
  puts "Request allowed? #{checker.allow_request?}"
  sleep(1)
  puts "Request allowed? #{checker.allow_request?}"
end
