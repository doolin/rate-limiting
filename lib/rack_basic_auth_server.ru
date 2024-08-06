# frozen_string_literal: true

require 'rack'
require 'json'
require 'base64'
require 'redis'
# require 'rspec/autorun' if ENV['RACK_TEST']
require_relative 'token_bucket'

# Show a dumb way to implement basic auth in a rack application
class BasicAuth
  def userpass(auth_header)
    userpass_encoded = auth_header.sub(/^Basic\s+/, '')
    userpass = Base64.decode64 userpass_encoded
    userpass.split(':')
  end

  def authenticated?(username, password)
    return true if username == 'username1' && password == 'password'

    false
  end

  def call(env)
    # TODO: Refactor into function
    auth_header = env['HTTP_AUTHORIZATION']

    # Implement actual checking per TODO below
    username, password = userpass(auth_header)

    # TODO: Implement the Basic Auth system, returning 200 for success,
    # 401 for unauthorized.
    # binding.pry
    # [200, {"Content-Type" => "text/plain; charset=utf-8"}, ["Hello #{username}"]]
    #
    # TODO: for some reason the body is not being returned.
    return unless authenticated?(username, password)

    response_body = {
      'salutations' => "Hello #{username}",
      'foo' => 'bar'
    }.to_json
    [200, { 'Content-Type' => 'application/json' }, [response_body]]
  end
end

# TODO: create an actual testing framework for these examples.
# Google search on "testing rackup file" returned
# http://testing-for-beginners.rubymonstas.org/rack_test/rack.html
#
# The challenge here is having both the convenience of specs written
# into the class file, and being able to run the class from elsehwere
# without the specs being invoked.

app = Rack::Builder.new do
  use TokenBucket, bucket_size: 1, refill_rate: 1, redis_key: 'new_rate_limit'
  run BasicAuth.new
end

run app
