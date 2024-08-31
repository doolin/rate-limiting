require 'rack/test'
require 'rspec'
require 'redis'
require_relative '../lib/leaking_bucket' # Adjust the path to where your LeakingBucket class is defined

RSpec.describe LeakingBucket do
  include Rack::Test::Methods

  let(:redis_key) { 'test_rate_limit' }

  let(:app) do
    key = redis_key
    size = bucket_size
    rate = leak_rate
    Rack::Builder.new do
      use LeakingBucket, bucket_size: size, leak_rate: rate, redis_key: key
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

  after(:each) do
    redis.flushdb
  end

  context 'with the standard leak rate and bucket size' do
    let(:leak_rate) { 2 }
    let(:bucket_size) { 10 }

    it 'allows requests within the capacity of the bucket' do
      10.times do
        get '/'
        expect(last_response.status).to eq(200)
      end
    end

    it 'rejects requests when the bucket is full' do
      10.times { get '/' }
      get '/'
      get '/'
      expect(last_response.status).to eq(429) # Assuming 429 Too Many Requests for rate limiting
    end

    it 'allows new requests after some time has passed and the bucket leaks' do
      10.times { get '/' }
      sleep(5) # Assuming a leaking rate of 2 requests per second
      get '/'
      expect(last_response.status).to eq(200)
    end

    it 'handles a burst of requests correctly' do
      15.times do |i|
        get '/'
        if i < 10
          expect(last_response.status).to eq(200)
        else
          expect(last_response.status).to eq(429)
        end
      end
    end

    it 'resets correctly after the bucket overflows and time passes' do
      10.times { get '/' }
      get '/'
      expect(last_response.status).to eq(429) # Bucket should be full here

      sleep(5) # Enough time for the bucket to leak
      get '/'
      expect(last_response.status).to eq(200) # Bucket should have capacity now
    end

    it 'handles requests from multiple clients independently' do
      client1_key = 'client1'
      client2_key = 'client2'

      Rack::Builder.new do
        use LeakingBucket, bucket_size: 10, leak_rate: 2, redis_key: client1_key
        run ->(env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
      end.to_app

      10.times { get '/', {}, 'HTTP_CLIENT_ID' => client1_key }
      get '/', {}, 'HTTP_CLIENT_ID' => client1_key
      expect(last_response.status).to eq(429) # Client 1 should be rate-limited

      get '/', {}, 'HTTP_CLIENT_ID' => client2_key
      expect(last_response.status).to eq(200) # Client 2 should not be rate-limited
    end
  end

  context 'with small bucket size and leak rate' do
    let(:leak_rate) { 2 }
    let(:bucket_size) { 1 }

    it 'handles a very small bucket size correctly' do
      # key = redis_key
      # small_bucket_app = Rack::Builder.new do
      #   use LeakingBucket, bucket_size: 1, leak_rate: 2, redis_key: key
      #   run ->(env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
      # end.to_app

      get '/'
      expect(last_response.status).to eq(200) # First request should be allowed

      get '/'
      expect(last_response.status).to eq(429) # Second request should be rate-limited
    end
  end

  context 'with a zero leak rate' do
    let(:leak_rate) { 0 }
    let(:bucket_size) { 5 }

    it 'handles a zero leak rate by permanently filling the bucket' do
      # key = redis_key
      # no_leak_app = Rack::Builder.new do
      #   use LeakingBucket, bucket_size: 5, leak_rate: 0, redis_key: key
      #   run ->(env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
      # end.to_app

      5.times { get '/' }
      get '/'
      expect(last_response.status).to eq(429) # Bucket should be full and not leak
    end
  end
end
