#!/usr/bin/env ruby
# frozen_string_literal: true

require 'redis'

# This class implements a token bucket for rate limiting.
# The "checket" part is for sanity checking.
class TokenBucket
  attr_reader :app, :bucket_size, :refill_rate, :redis_key

  def initialize(app, bucket_size:, refill_rate:, redis_key:)
    @app = app
    @bucket_size = bucket_size
    @refill_rate = refill_rate # Tokens added per second
    @redis_key = redis_key
    # @redis = Redis.new(port: 6380) # Connect to Dockerized Redis on localhost:6380
    # @redis = Redis.new(host: 'redis')
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
    @redis.watch("#{@redis_key}:tokens") do
      current_tokens = @redis.get("#{@redis_key}:tokens").to_i
      last_refill = @redis.get("#{@redis_key}:timestamp").to_f

      # Calculate time passed since the last token was drawn
      time_passed = current_time - last_refill
      new_tokens = (time_passed * @refill_rate).floor

      # Refill the bucket if possible
      current_tokens = [@bucket_size, current_tokens + new_tokens].min

      if current_tokens.positive?
        @redis.multi do |multi|
          multi.set("#{@redis_key}:tokens", current_tokens - 1)
          multi.set("#{@redis_key}:timestamp", current_time) if new_tokens.positive?
        end
        true
      else
        false
      end
    end
  end

  private

  def initialize_bucket
    # Set initial bucket and timestamp if not already set
    @redis.setnx("#{@redis_key}:tokens", @bucket_size)
    @redis.setnx("#{@redis_key}:timestamp", current_time)
  end

  def current_time
    Time.now.to_f
  end
end

# Step 2: Make it self-executable and provide example usage
if __FILE__ == $PROGRAM_NAME
  # checker = TokenBucket.new(bucket_size: 10, refill_rate: 1, redis_key: 'my_rate_limit')

  # # Example invocations
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"
  # sleep(2)
  # puts "Request allowed? #{checker.allow_request?}"

  checker = TokenBucket.new(bucket_size: 1, refill_rate: 1, redis_key: 'new_rate_limit')
  puts "Request allowed? #{checker.allow_request?}"
  sleep(0.5)
  puts "Request allowed? #{checker.allow_request?}"
  puts "Request allowed? #{checker.allow_request?}"
  sleep(1)
  puts "Request allowed? #{checker.allow_request?}"
end
