require 'rack/test'
require 'rspec'
require_relative '../lib/sliding_window_log'

RSpec.describe SlidingWindowLog do # rubocop:disable Metrics/BlockLength
  include Rack::Test::Methods

  let(:redis_key) { 'test_rate_limit' }

  # Refactor the app to use `let` block, so `redis_key` can be used
  let(:app) do
    key = redis_key
    Rack::Builder.new do
      use(SlidingWindowLog, time_interval: 1, rate: 1, redis_key: key)
      run ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
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

  before do
    redis.del(redis_key)
  end

  it 'allows the first request' do
    get '/'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('OK')
  end

  it 'limits requests exceeding the count in the fixed window' do
    # First request should pass
    get '/'
    expect(last_response.status).to eq(200)

    sleep 1
    # Second request should also pass (bucket size is 2)
    get '/'
    expect(last_response.status).to eq(200)

    # Third request should be rate limited
    # Reenable this later
    get '/'
    expect(last_response.status).to eq(429)
    expect(last_response.body).to eq('Rate limit exceeded')
  end

  it 'refills the bucket after enough time has passed' do
    # Use up all tokens
    2.times { get '/' }
    expect(last_response.status).to eq(429)
    expect(last_response.body).to eq('Rate limit exceeded')

    # Wait for refill (adjust sleep time to match your refill rate)
    sleep(1.5)

    # Now, the next request should pass as the bucket refills
    get '/'
    expect(last_response.status).to eq(200)
  end
end
