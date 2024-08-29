# frozen_string_literal: true

require 'rack'
require 'json'
require 'base64'
require 'redis'

require_relative 'token_bucket'

# Wrapper for testing the TokenBucket class.
# This class is not meant to be used in production.
class DemoApp
  def userpass(auth_header)
    userpass_encoded = auth_header.sub(/^Basic\s+/, '')
    userpass = Base64.decode64 userpass_encoded
    userpass.split(':')
  end

  def call(env)
    response_body = {
      'salutations' => 'Hello!',
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
  run DemoApp.new
end

run app
