#!/usr/bin/env ruby
# frozen_string_literal: true

require 'redis'

# This class implements a token bucket for rate limiting.
# The "checket" part is for sanity checking.
class FixedWindowCounter
  attr_reader :app

  def initialize(app, time_interval:, rate:, redis_key:)
    @app = app
    @time_interval = time_interval
    @rate = rate
    @redis_key = redis_key
  end

  def call(env)
    @app.call(env)
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
