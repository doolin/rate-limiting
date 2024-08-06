require 'rack/test'
require 'rspec'
require_relative '../lib/token_bucket' # Adjust the path to where your TokenBucket class is defined

RSpec.describe TokenBucket do
  include Rack::Test::Methods

  let(:app) do
    Rack::Builder.new do
      use TokenBucket, bucket_size: 2, refill_rate: 1, redis_key: 'test_rate_limit'
      run ->(env) { [200, {'Content-Type' => 'text/plain'}, ['OK']] }
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
    redis.del('test_rate_limit:tokens')
    redis.del('test_rate_limit:timestamp')
  end

  it "allows the first request" do
    get '/'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('OK')
  end

  it "limits requests exceeding the token bucket" do
    # First request should pass
    get '/'
    expect(last_response.status).to eq(200)

    # Second request should also pass (bucket size is 2)
    get '/'
    expect(last_response.status).to eq(200)

    # Third request should be rate limited
    get '/'
    expect(last_response.status).to eq(429)
    expect(last_response.body).to eq('Rate limit exceeded')
  end

  it "refills the bucket after enough time has passed" do
    # Use up all tokens
    2.times { get '/' }

    # Wait for refill (adjust sleep time to match your refill rate)
    sleep(1)

    # Now, the next request should pass as the bucket refills
    get '/'
    expect(last_response.status).to eq(200)
  end
end

