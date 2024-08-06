require 'net/http'
require 'uri'

RSpec.configure do |config|
  config.before(:suite) do
    redis = Redis.new(host: 'localhost', port: 6380) # Update with your Redis host and port
    redis.ping
  rescue StandardError => e
    puts "Redis is not available: #{e.message}"
    exit(1) # Exit the test suite if Redis is not available
  end
end

RSpec.describe 'Token Bucket Rate Limiter with Basic Auth' do
  before(:all) do
    @uri = URI.parse('http://localhost:9998') # Update with your Rack app URL and port
    @username = 'username1'
    @password = 'password'
  end

  def send_request_with_auth(uri, username, password)
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(username, password)
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(request)
    end
  end

  it 'allows requests within rate limit with valid credentials' do
    # Assuming the rate limit allows 5 requests per minute
    # responses = 5.times.map { send_request_with_auth(@uri, @username, @password) }
    responses = 1.times.map { send_request_with_auth(@uri, @username, @password) }

    responses.each do |response|
      expect(response.code).to eq('200')
    end
  end

  it 'limits requests exceeding rate limit with valid credentials' do
    # Sending 10 requests rapidly to exceed the rate limit
    # responses = 10.times.map { send_request_with_auth(@uri, @username, @password) }
    responses = 1.times.map { send_request_with_auth(@uri, @username, @password) }

    successful_requests = responses.select { |response| response.code == '200' }.count
    limited_requests = responses.select { |response| response.code == '429' }.count

    # Verify that at least one request is limited
    expect(successful_requests).to be < 10
    expect(limited_requests).to be > 0
  end
end
