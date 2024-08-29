require 'rack/test'
require 'rspec'
require_relative '../lib/leaking_bucket' # Adjust the path to where your LeakingBucket class is defined

RSpec.describe LeakingBucket do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.new do
      use LeakingBucket, bucket_size: 2, refill_rate: 1, redis_key: 'test_rate_limit'
      run ->(env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
    end.to_app
  end

  before(:all) do
    ENV['REDIS_HOST'] = 'localhost'
    ENV['REDIS_PORT'] = '6380'
  end

  after(:all) do
    ENV['REDIS_HOST'] = nil
    ENV['REDIS_PORT'] = nil
  end

  let(:redis) { Redis.new(port: 6380) }
end
